# work from latest LTS ubuntu release
FROM ubuntu:18.04

# set the environment variables
ENV somalier_version 0.1.4
ENV htslib_version 1.9
ENV nim_version 0.19.4

# run update and install necessary tools from package manager
RUN apt-get update -y && apt-get install -y \
    build-essential \
    git \
    curl \
    wget \
    vim \
    zlib1g-dev \
    xz-utils \
    libbz2-dev \
    libssl-dev \
    libcurl4-openssl-dev \
    libnss-sss \
    autoconf \
    bzip2 \
    libncurses5-dev \
    libncursesw5-dev \
    liblzma-dev \
    gzip

# install nim
WORKDIR /usr/local/bin
RUN curl -SL https://nim-lang.org/download/nim-${nim_version}.tar.xz > nim-${nim_version}.tar.xz
RUN tar -xvf nim-${nim_version}.tar.xz
WORKDIR /usr/local/bin/nim-${nim_version}
RUN sh build.sh
RUN bin/nim c koch
RUN ./koch nimble
RUN ln -s /usr/local/bin/nim-0.19.4/bin/nim /usr/local/bin/nim
RUN ln -s /usr/local/bin/nim-0.19.4/bin/nimble /usr/local/bin/nimble

# install htslib
WORKDIR /usr/local/bin/
RUN curl -SL https://github.com/samtools/htslib/releases/download/${htslib_version}/htslib-${htslib_version}.tar.bz2 \
    > /usr/local/bin/htslib-${htslib_version}.tar.bz2
RUN tar -xjf /usr/local/bin/htslib-${htslib_version}.tar.bz2 -C /usr/local/bin/
RUN cd /usr/local/bin/htslib-${htslib_version}/ && ./configure
RUN cd /usr/local/bin/htslib-${htslib_version}/ && make
RUN cd /usr/local/bin/htslib-${htslib_version}/ && make install
ENV LD_LIBRARY_PATH /usr/local/bin/htslib-${htslib_version}/

# install bpbio
WORKDIR /usr/local/bin
RUN nimble install -y hts binaryheap https://github.com/brentp/bpbio

# get somalier
WORKDIR /usr/local/bin
RUN curl -SL https://github.com/brentp/somalier/archive/v${somalier_version}.tar.gz \
     > v${somalier_version}.tar.gz
RUN tar -xzvf v${somalier_version}.tar.gz
WORKDIR /usr/local/bin/somalier-${somalier_version}
RUN nim c -d:release -o:/usr/local/bin/somalier --passC:-flto src/somalier

# download some helper files
WORKDIR /opt
RUN wget https://github.com/brentp/somalier/files/2866407/sites.hg38.vcf.gz
RUN gunzip sites.hg38.vcf.gz
RUN wget https://github.com/brentp/somalier/files/2866408/sites.chr.hg38.vcf.gz
RUN mv sites.chr.hg38.vcf.gz sites.chr.hg38.vcf
#RUN gunzip sites.chr.hg38.vcf.gz
RUN wget -O sites.hg37.vcf.gz https://github.com/brentp/somalier/files/2774846/sites.vcf.gz
RUN gunzip sites.hg37.vcf.gz

# set default command
CMD ["somalier"]

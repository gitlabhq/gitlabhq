FROM ruby:2.6-stretch
LABEL maintainer "Grzegorz Bizon <grzegorz@gitlab.com>"
ENV DEBIAN_FRONTEND noninteractive

##
# Add support for stretch-backports
#
RUN echo "deb http://ftp.debian.org/debian stretch-backports main" >> /etc/apt/sources.list

##
# Update APT sources and install some dependencies
#
RUN sed -i "s/httpredir.debian.org/ftp.us.debian.org/" /etc/apt/sources.list
RUN apt-get update && apt-get install -y wget unzip xvfb lsb-release

##
# Install some packages from backports
#
RUN apt-get -y -t stretch-backports install git git-lfs

##
# Install Docker
#
RUN wget -q https://download.docker.com/linux/static/stable/x86_64/docker-17.09.0-ce.tgz && \
    tar -zxf docker-17.09.0-ce.tgz && mv docker/docker /usr/local/bin/docker && \
    rm docker-17.09.0-ce.tgz

##
# Install Google Chrome version with headless support
#
RUN curl -sS -L https://dl.google.com/linux/linux_signing_key.pub | apt-key add -
RUN echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" > /etc/apt/sources.list.d/google.list
RUN apt-get update -q && apt-get install -y google-chrome-stable && apt-get clean

##
# Install chromedriver to make it work with Selenium
#
RUN wget -q https://chromedriver.storage.googleapis.com/$(wget -q -O - https://chromedriver.storage.googleapis.com/LATEST_RELEASE)/chromedriver_linux64.zip
RUN unzip chromedriver_linux64.zip -d /usr/local/bin

##
# Install gcloud and kubectl CLI used in Auto DevOps test to create K8s
# clusters
#
RUN export CLOUD_SDK_REPO="cloud-sdk-$(lsb_release -c -s)" && \
    echo "deb http://packages.cloud.google.com/apt $CLOUD_SDK_REPO main" | tee -a /etc/apt/sources.list.d/google-cloud-sdk.list && \
    curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add - && \
    apt-get update -y && apt-get install google-cloud-sdk kubectl -y

WORKDIR /home/gitlab/qa
COPY ./qa/Gemfile* /home/gitlab/qa/
COPY ./config/initializers/0_inject_enterprise_edition_module.rb /home/gitlab/config/initializers/
# Copy VERSION to ensure the COPY succeeds to copy at least one file since ee/app/models/license.rb isn't present in FOSS
# The [b] part makes ./ee/app/models/license.r[b] a pattern that is allowed to return no files (which is the case in FOSS)
COPY VERSION ./ee/app/models/license.r[b] /home/gitlab/ee/app/models/
COPY ./lib/gitlab.rb /home/gitlab/lib/
COPY ./lib/gitlab/utils.rb /home/gitlab/lib/gitlab/
COPY ./INSTALLATION_TYPE ./VERSION /home/gitlab/
RUN cd /home/gitlab/qa/ && bundle install --jobs=$(nproc) --retry=3 --quiet
COPY ./qa /home/gitlab/qa

ENTRYPOINT ["bin/test"]

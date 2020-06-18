FROM ruby:2.6-stretch
LABEL maintainer="GitLab Quality Department <quality@gitlab.com>"

ENV DEBIAN_FRONTEND="noninteractive"
ENV DOCKER_VERSION="17.09.0-ce"
ENV CHROME_VERSION="83.0.4103.61-1"
ENV CHROME_DRIVER_VERSION="83.0.4103.39"
ENV CHROME_DEB="google-chrome-stable_${CHROME_VERSION}_amd64.deb"
ENV CHROME_URL="https://s3.amazonaws.com/gitlab-google-chrome-stable/${CHROME_DEB}"
ENV K3D_VERSION="1.3.4"

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
RUN wget -q "https://download.docker.com/linux/static/stable/x86_64/docker-${DOCKER_VERSION}.tgz" && \
    tar -zxf "docker-${DOCKER_VERSION}.tgz" && mv docker/docker /usr/local/bin/docker && \
    rm "docker-${DOCKER_VERSION}.tgz"

##
# Install Google Chrome version with headless support
# Download from our local S3 bucket, populated by https://gitlab.com/gitlab-org/gitlab-build-images/-/blob/master/scripts/cache-google-chrome
#
RUN curl --silent --show-error --fail -O "${CHROME_URL}" && \
    dpkg -i "./${CHROME_DEB}" || true && \
    apt-get install -f -y && \
    rm -f "./${CHROME_DEB}"

##
# Install chromedriver to make it work with Selenium
#
RUN wget -q "https://chromedriver.storage.googleapis.com/${CHROME_DRIVER_VERSION}/chromedriver_linux64.zip"
RUN unzip chromedriver_linux64.zip -d /usr/local/bin
RUN rm -f chromedriver_linux64.zip

##
# Install K3d local cluster support
#   https://github.com/rancher/k3d
#
RUN curl -s https://raw.githubusercontent.com/rancher/k3d/master/install.sh | TAG="v${K3D_VERSION}" bash

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

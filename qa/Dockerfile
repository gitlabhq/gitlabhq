FROM ruby:2.3
LABEL maintainer "Grzegorz Bizon <grzegorz@gitlab.com>"

RUN sed -i "s/httpredir.debian.org/ftp.us.debian.org/" /etc/apt/sources.list && \
    apt-get update && apt-get install -y --force-yes \
      libqt5webkit5-dev qt5-qmake qt5-default build-essential xvfb git && \
    apt-get clean

WORKDIR /home/qa

COPY ./ ./
RUN bundle install

ENTRYPOINT ["bin/test"]

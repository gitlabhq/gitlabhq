FROM ruby:2.3
LABEL maintainer "Grzegorz Bizon <grzegorz@gitlab.com>"

ENV CHROME_VERSION 59.0.3071.104-1
ENV CHROME_DRIVER_VERSION 2.30

##
# Update APT sources and install some dependencies
#
RUN sed -i "s/httpredir.debian.org/ftp.us.debian.org/" /etc/apt/sources.list
RUN apt-get update && apt-get install -y wget git unzip xvfb

##
# Install Google Chrome version with headless support
#
RUN curl -sS -L https://dl.google.com/linux/linux_signing_key.pub | apt-key add -
RUN echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" > /etc/apt/sources.list.d/google.list
RUN apt-get update -q && DEBIAN_FRONTEND=noninteractive apt-get install -y google-chrome-stable=$CHROME_VERSION

##
# Install chromedriver to make it work with Selenium
#
RUN wget -q https://chromedriver.storage.googleapis.com/$CHROME_DRIVER_VERSION/chromedriver_linux64.zip
RUN unzip chromedriver_linux64.zip -d /usr/local/bin

RUN apt-get clean

WORKDIR /home/qa

COPY ./Gemfile* ./

RUN bundle install

COPY ./ ./

ENTRYPOINT ["bin/test"]

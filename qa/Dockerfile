FROM ruby:2.3
LABEL maintainer "Grzegorz Bizon <grzegorz@gitlab.com>"

##
# Update APT sources and install some dependencies
#
RUN sed -i "s/httpredir.debian.org/ftp.us.debian.org/" /etc/apt/sources.list
RUN apt-get update && apt-get install -y wget git unzip xvfb

##
# Google Chrome 59 is the first version with headless support
#
RUN wget -q https://dl.google.com/linux/chrome/deb/pool/main/g/google-chrome-stable/google-chrome-stable_59.0.3071.86-1_amd64.deb
RUN dpkg -i google-chrome-stable_59.0.3071.86-1_amd64.deb; apt-get -fy install

##
# Install chromedriver to make it work with Selenium
#
RUN wget -q https://chromedriver.storage.googleapis.com/2.29/chromedriver_linux64.zip
RUN unzip chromedriver_linux64.zip -d /usr/local/bin

RUN apt-get clean

WORKDIR /home/qa

COPY ./Gemfile* ./

RUN bundle install

COPY ./ ./

ENTRYPOINT ["bin/test"]

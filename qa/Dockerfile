FROM ruby:2.3
LABEL maintainer "Grzegorz Bizon <grzegorz@gitlab.com>"

##
# Update APT sources and install some dependencies
#
RUN sed -i "s/httpredir.debian.org/ftp.us.debian.org/" /etc/apt/sources.list
RUN apt-get update && apt-get install -y wget git unzip xvfb

##
# At this point Google Chrome Beta is 59 - first version with headless support
#
RUN wget -q https://dl.google.com/linux/direct/google-chrome-beta_current_amd64.deb
RUN dpkg -i google-chrome-beta_current_amd64.deb; apt-get -fy install

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

#!/bin/bash

if [ -f /.dockerinit ]; then
    # Docker runners use `/cache` folder which is persisted every build
    if [ ! -e /cache/phantomjs_1.9.8-0jessie_amd64.deb ]; then
        wget -q https://gitlab.com/axil/phantomjs-debian/raw/master/phantomjs_1.9.8-0jessie_amd64.deb
        mv phantomjs_1.9.8-0jessie_amd64.deb /cache
    fi
    dpkg -i /cache/phantomjs_1.9.8-0jessie_amd64.deb

    apt-get update -qq
    apt-get -o dir::cache::archives="/cache/apt" install -y -qq --force-yes \
        libicu-dev libkrb5-dev cmake nodejs postgresql-client mysql-client unzip

    cp config/database.yml.mysql config/database.yml
    sed -i 's/username:.*/username: root/g' config/database.yml
    sed -i 's/password:.*/password:/g' config/database.yml
    sed -i 's/# socket:.*/host: mysql/g' config/database.yml

    cp config/resque.yml.example config/resque.yml
    sed -i 's/localhost/redis/g' config/resque.yml

    export FLAGS=(--path /cache)
else
    export PATH=$HOME/bin:/usr/local/bin:/usr/bin:/bin
    cp config/database.yml.mysql config/database.yml
    sed "s/username\:.*$/username\: runner/" -i config/database.yml
    sed "s/password\:.*$/password\: 'password'/" -i config/database.yml
    sed "s/gitlabhq_test/gitlabhq_test_$((RANDOM/5000))/" -i config/database.yml
fi

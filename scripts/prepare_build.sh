#!/bin/bash
if [ -f /.dockerinit ]; then
    wget -q http://ftp.de.debian.org/debian/pool/main/p/phantomjs/phantomjs_1.9.0-1+b1_amd64.deb
    dpkg -i phantomjs_1.9.0-1+b1_amd64.deb

    apt-get update -qq
    apt-get install -y -qq libicu-dev libkrb5-dev cmake nodejs postgresql-client mysql-client

    cp config/database.yml.mysql config/database.yml
    sed -i 's/username:.*/username: root/g' config/database.yml
    sed -i 's/password:.*/password:/g' config/database.yml
    sed -i 's/# socket:.*/host: mysql/g' config/database.yml

    cp config/resque.yml.example config/resque.yml
    sed -i 's/localhost/redis/g' config/resque.yml
    FLAGS=(--deployment --path /cache)
    export FLAGS
else
    export PATH=$HOME/bin:/usr/local/bin:/usr/bin:/bin
    cp config/database.yml.mysql config/database.yml
    sed "s/username\:.*$/username\: runner/" -i config/database.yml
    sed "s/password\:.*$/password\: 'password'/" -i config/database.yml
    sed "s/gitlabhq_test/gitlabhq_test_$((RANDOM/5000))/" -i config/database.yml
fi

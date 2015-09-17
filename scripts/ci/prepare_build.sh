#!/bin/bash
if [ -f /.dockerinit ]; then
    export FLAGS=(--deployment --path /cache)

    apt-get update -qq
    apt-get install -y -qq nodejs

    wget -q http://ftp.de.debian.org/debian/pool/main/p/phantomjs/phantomjs_1.9.0-1+b1_amd64.deb
    dpkg -i phantomjs_1.9.0-1+b1_amd64.deb

    cp config/database.yml.mysql config/database.yml
    sed -i "s/username:.*/username: root/g" config/database.yml
    sed -i "s/password:.*/password:/g" config/database.yml
    sed -i "s/# socket:.*/host: mysql/g" config/database.yml
else
    export PATH=$HOME/bin:/usr/local/bin:/usr/bin:/bin

    cp config/database.yml.mysql config/database.yml
    sed -i "s/username\:.*$/username\: runner/" config/database.yml
    sed -i "s/password\:.*$/password\: 'password'/" config/database.yml
    sed -i "s/gitlab_ci_test/gitlab_ci_test_$((RANDOM/5000))/" config/database.yml
fi

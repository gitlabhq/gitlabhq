#!/bin/bash

retry() {
    for i in $(seq 1 3); do
        if eval "$@"; then
            return 0
        fi
        sleep 3s
        echo "Retrying..."
    done
    return 1
}

if [ -f /.dockerinit ]; then
    mkdir -p vendor

    # Install phantomjs package
    pushd vendor
    if [ ! -e phantomjs_1.9.8-0jessie_amd64.deb ]; then
        wget -q https://gitlab.com/axil/phantomjs-debian/raw/master/phantomjs_1.9.8-0jessie_amd64.deb
    fi
    dpkg -i phantomjs_1.9.8-0jessie_amd64.deb
    popd

    # Try to install packages
    retry 'apt-get update -yqqq; apt-get -o dir::cache::archives="vendor/apt" install -y -qq --force-yes \
      libicu-dev libkrb5-dev cmake nodejs postgresql-client mysql-client unzip'

    cp config/database.yml.mysql config/database.yml
    sed -i 's/username:.*/username: root/g' config/database.yml
    sed -i 's/password:.*/password:/g' config/database.yml
    sed -i 's/# socket:.*/host: mysql/g' config/database.yml

    cp config/resque.yml.example config/resque.yml
    sed -i 's/localhost/redis/g' config/resque.yml

    export FLAGS=(--path vendor --retry 3)
else
    export PATH=$HOME/bin:/usr/local/bin:/usr/bin:/bin
    cp config/database.yml.mysql config/database.yml
    sed "s/username\:.*$/username\: runner/" -i config/database.yml
    sed "s/password\:.*$/password\: 'password'/" -i config/database.yml
    sed "s/gitlabhq_test/gitlabhq_test_$((RANDOM/5000))/" -i config/database.yml
fi

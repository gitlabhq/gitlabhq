#!/bin/bash

retry() {
    if eval "$@"; then
        return 0
    fi

    for i in 2 1; do
        sleep 3s
        echo "Retrying $i..."
        if eval "$@"; then
            return 0
        fi
    done
    return 1
}

if [ -f /.dockerenv ] || [ -f ./dockerinit ]; then
    mkdir -p vendor/apt

    # Install phantomjs package
    pushd vendor/apt
    PHANTOMJS_FILE="phantomjs-$PHANTOMJS_VERSION-linux-x86_64"
    if [ ! -d "$PHANTOMJS_FILE" ]; then
        curl -q -L "https://s3.amazonaws.com/gitlab-build-helpers/$PHANTOMJS_FILE.tar.bz2" | tar jx
    fi
    cp "$PHANTOMJS_FILE/bin/phantomjs" "/usr/bin/"
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

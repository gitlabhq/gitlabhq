#!/bin/sh

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

cp config/database.yml.mysql config/database.yml
sed -i 's/username:.*/username: root/g' config/database.yml
sed -i 's/password:.*/password:/g' config/database.yml
sed -i 's/# socket:.*/host: mysql/g' config/database.yml

cp config/resque.yml.example config/resque.yml
sed -i 's/localhost/redis/g' config/resque.yml

export FLAGS="--path vendor --retry 3 --quiet"

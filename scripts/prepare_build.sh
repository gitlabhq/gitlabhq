#!/bin/sh

. scripts/utils.sh

export SETUP_DB=${SETUP_DB:-true}
export GITLAB_DATABASE=${GITLAB_DATABASE:-postgresql}
export USE_BUNDLE_INSTALL=${USE_BUNDLE_INSTALL:-true}

if [ -f /.dockerenv ] || [ -f ./dockerinit ]; then
    cp config/database.yml.$GITLAB_DATABASE config/database.yml

    if [ "$GITLAB_DATABASE" = 'postgresql' ]; then
        sed -i 's/# host:.*/host: postgres/g' config/database.yml
    else # Assume it's mysql
        sed -i 's/username:.*/username: root/g' config/database.yml
        sed -i 's/password:.*/password:/g' config/database.yml
        sed -i 's/# socket:.*/host: mysql/g' config/database.yml
    fi

    cp config/resque.yml.example config/resque.yml
    sed -i 's/localhost/redis/g' config/resque.yml

    export FLAGS="--path vendor --retry 3 --quiet"
else
    rnd=$(awk 'BEGIN { srand() ; printf("%d\n",rand()*5) }')
    export PATH="$HOME/bin:/usr/local/bin:/usr/bin:/bin"
    cp config/database.yml.$GITLAB_DATABASE config/database.yml
    sed "s/username\:.*$/username\: runner/" -i config/database.yml
    sed "s/password\:.*$/password\: 'password'/" -i config/database.yml
    sed "s/gitlabhq_test/gitlabhq_test_$rnd/" -i config/database.yml
fi

cp config/gitlab.yml.example config/gitlab.yml

if [ "$USE_BUNDLE_INSTALL" != "false" ]; then
    retry bundle install --without production --jobs $(nproc) --clean $FLAGS
fi

# Only install knapsack after bundle install! Otherwise oddly some native
# gems could not be found under some circumstance. No idea why, hours wasted.
retry gem install knapsack fog-aws mime-types

if [ "$SETUP_DB" != "false" ]; then
    bundle exec rake db:drop db:create db:schema:load db:migrate

    if [ "$GITLAB_DATABASE" = "mysql" ]; then
        bundle exec rake add_limits_mysql
    fi
fi

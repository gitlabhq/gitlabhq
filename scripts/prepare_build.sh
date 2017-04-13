#!/bin/sh

. scripts/utils.sh

export SETUP_DB=${SETUP_DB:-true}
export USE_BUNDLE_INSTALL=${USE_BUNDLE_INSTALL:-true}

# Determine the database by looking at the job name.
# For example, we'll get pg if the job is `rspec pg 19 20`
export GITLAB_DATABASE=$(echo $CI_JOB_NAME | cut -f2 -d' ')

# This would make the default database postgresql, and we could also use
# pg to mean postgresql.
if [ "$GITLAB_DATABASE" != 'mysql' ]; then
    export GITLAB_DATABASE='postgresql'
fi

cp config/database.yml.$GITLAB_DATABASE config/database.yml

if [ "$GITLAB_DATABASE" = 'postgresql' ]; then
    sed -i 's/# host:.*/host: postgres/g' config/database.yml
else # Assume it's mysql
    sed -i 's/username:.*/username: root/g' config/database.yml
    sed -i 's/password:.*/password:/g' config/database.yml
    sed -i 's/# host:.*/host: mysql/g' config/database.yml
fi

cp config/resque.yml.example config/resque.yml
sed -i 's/localhost/redis/g' config/resque.yml

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

export FLAGS="--path vendor --retry 3 --quiet"

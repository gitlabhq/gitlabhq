. scripts/utils.sh

export SETUP_DB=${SETUP_DB:-true}
export CREATE_DB_USER=${CREATE_DB_USER:-$SETUP_DB}
export USE_BUNDLE_INSTALL=${USE_BUNDLE_INSTALL:-true}
export BUNDLE_INSTALL_FLAGS="--without=production --jobs=$(nproc) --path=vendor --retry=3 --quiet"

if [ "$USE_BUNDLE_INSTALL" != "false" ]; then
    bundle install --clean $BUNDLE_INSTALL_FLAGS && bundle check
fi

# Only install knapsack after bundle install! Otherwise oddly some native
# gems could not be found under some circumstance. No idea why, hours wasted.
retry gem install knapsack

cp config/gitlab.yml.example config/gitlab.yml
sed -i 's/bin_path: \/usr\/bin\/git/bin_path: \/usr\/local\/bin\/git/' config/gitlab.yml

# Determine the database by looking at the job name.
# For example, we'll get pg if the job is `rspec-pg 19 20`
export GITLAB_DATABASE=$(echo $CI_JOB_NAME | cut -f1 -d' ' | cut -f2 -d-)

# This would make the default database postgresql, and we could also use
# pg to mean postgresql.
if [ "$GITLAB_DATABASE" != 'mysql' ]; then
    export GITLAB_DATABASE='postgresql'
fi

cp config/database.yml.$GITLAB_DATABASE config/database.yml

# Set user to a non-superuser to ensure we test permissions
sed -i 's/username: root/username: gitlab/g' config/database.yml

if [ "$GITLAB_DATABASE" = 'postgresql' ]; then
    sed -i 's/localhost/postgres/g' config/database.yml
else # Assume it's mysql
    sed -i 's/localhost/mysql/g' config/database.yml
fi

cp config/resque.yml.example config/resque.yml
sed -i 's/localhost/redis/g' config/resque.yml

cp config/redis.cache.yml.example config/redis.cache.yml
sed -i 's/localhost/redis/g' config/redis.cache.yml

cp config/redis.queues.yml.example config/redis.queues.yml
sed -i 's/localhost/redis/g' config/redis.queues.yml

cp config/redis.shared_state.yml.example config/redis.shared_state.yml
sed -i 's/localhost/redis/g' config/redis.shared_state.yml

# Some tasks (e.g. db:seed_fu) need to have a properly-configured database
# user but not necessarily a full schema loaded
if [ "$CREATE_DB_USER" != "false" ]; then
    if [ "$GITLAB_DATABASE" = 'postgresql' ]; then
        . scripts/create_postgres_user.sh
    else
        . scripts/create_mysql_user.sh
    fi
fi

if [ "$SETUP_DB" != "false" ]; then
    bundle exec rake db:drop db:create db:schema:load db:migrate

    if [ "$GITLAB_DATABASE" = "mysql" ]; then
        bundle exec rake add_limits_mysql
    fi
fi

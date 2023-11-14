. scripts/utils.sh

export SETUP_DB=${SETUP_DB:-true}
export USE_BUNDLE_INSTALL=${USE_BUNDLE_INSTALL:-true}

if [ "$USE_BUNDLE_INSTALL" != "false" ]; then
  bundle_install_script
fi

cp config/gitlab.yml.example config/gitlab.yml
sed -i 's/bin_path: \/usr\/bin\/git/bin_path: \/usr\/local\/bin\/git/' config/gitlab.yml

cp config/cable.yml.example config/cable.yml
sed -i 's|url:.*$|url: redis://redis:6379|g' config/cable.yml

cp config/resque.yml.example config/resque.yml
sed -i 's|url:.*$|url: redis://redis:6379|g' config/resque.yml

# By default, run CI against Redis Cluster to ensure Redis Cluster compatibility.
# if SETUP_DB is false, the jobs are not backend-related
if [[ "$USE_REDIS_CLUSTER" != "false" ]] && [[ "$SETUP_DB" != "false" ]]; then
  cp config/redis.yml.example config/redis.yml
  sed -i 's|- .*$|- redis://rediscluster:7001|g' config/redis.yml
  sed -i 's|url:.*$|url: redis://redis:6379|g' config/redis.yml
fi

setup_database_yml

if [ "$SETUP_DB" != "false" ]; then
  setup_db
elif getent hosts postgres; then
  setup_db_user_only
fi

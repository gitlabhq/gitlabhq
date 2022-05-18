. scripts/utils.sh

export SETUP_DB=${SETUP_DB:-true}
export USE_BUNDLE_INSTALL=${USE_BUNDLE_INSTALL:-true}

if [ "$USE_BUNDLE_INSTALL" != "false" ]; then
  bundle_install_script
fi

cp config/gitlab.yml.example config/gitlab.yml
sed -i 's/bin_path: \/usr\/bin\/git/bin_path: \/usr\/local\/bin\/git/' config/gitlab.yml

if [ "$DECOMPOSED_DB" == "true" ]; then
  echo "Using decomposed database config (config/database.yml.decomposed-postgresql)"
  cp config/database.yml.decomposed-postgresql config/database.yml
else
  cp config/database.yml.postgresql config/database.yml
fi

# Remove Geo database setting if `ee/` directory does not exist. When it does
# not exist, it runs the GitLab test suite "as if FOSS", meaning the jobs run
# in the context of gitlab-org/gitlab-foss where the Geo is not available.
if [ ! -d "ee/" ] ; then
  sed -i '/geo:/,/^$/d' config/database.yml
fi

# Set user to a non-superuser to ensure we test permissions
sed -i 's/username: root/username: gitlab/g' config/database.yml

sed -i 's/localhost/postgres/g' config/database.yml
sed -i 's/username: git/username: postgres/g' config/database.yml

cp config/cable.yml.example config/cable.yml
sed -i 's|url:.*$|url: redis://redis:6379|g' config/cable.yml

cp config/resque.yml.example config/resque.yml
sed -i 's|url:.*$|url: redis://redis:6379|g' config/resque.yml

if [ "$SETUP_DB" != "false" ]; then
  setup_db
elif getent hosts postgres; then
  setup_db_user_only
fi

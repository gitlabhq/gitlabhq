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
  echo "Using decomposed database config (config/database.yml.postgresql)"
  cp config/database.yml.postgresql config/database.yml

  if [ "$CI_CONNECTION_DB" == "true" ]; then
    echo "Enabling ci connection (database_tasks: false) in config/database.yml"
    sed -i '/ci:/,/geo:/''s/^  # /  /g' config/database.yml
  fi
fi

# Set up Geo database if the job name matches `rspec-ee` or `geo`.
# Since Geo is an EE feature, we shouldn't set it up for non-EE tests.
if [[ "${CI_JOB_NAME}" =~ "rspec-ee" ]] || [[ "${CI_JOB_NAME}" =~ "geo" ]]; then
  echoinfo "Geo DB will be set up."
else
  echoinfo "Geo DB won't be set up."
  sed -i '/geo:/,/^$/d' config/database.yml
fi

# Set up Embedding database if the job name matches `rspec-ee`
# Since Embedding is an EE feature, we shouldn't set it up for non-EE tests.
if [[ "${CI_JOB_NAME}" =~ "rspec-ee" ]]; then
  echoinfo "Embedding DB will be set up."
else
  echoinfo "Embedding DB won't be set up."
  sed -i '/embedding:/,/^$/d' config/database.yml
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

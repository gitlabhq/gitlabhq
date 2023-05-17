function retry() {
  retry_times_sleep 2 3 "$@"
}

function retry_times_sleep() {
  number_of_retries="$1"
  shift
  sleep_seconds="$1"
  shift

  if eval "$@"; then
    return 0
  fi

  for i in $(seq "${number_of_retries}" -1 1); do
    sleep "$sleep_seconds"s
    echo "[$(date '+%H:%M:%S')] Retrying $i..."
    if eval "$@"; then
      return 0
    fi
  done

  return 1
}

# Retry after 2s, 4s, 8s, 16s, 32, 64s, 128s
function retry_exponential() {
  if eval "$@"; then
    return 0
  fi

  local sleep_time=0
  # The last try will be after 2**7 = 128 seconds (2min8s)
  for i in 1 2 3 4 5 6 7; do
    sleep_time=$((2 ** i))

    echo "Sleep for $sleep_time seconds..."
    sleep $sleep_time
    echo "[$(date '+%H:%M:%S')] Attempt #$i..."
    if eval "$@"; then
      return 0
    fi
  done

  return 1
}

function test_url() {
  local url="${1}"
  local curl_args="${2}"
  local status
  local cmd="curl ${curl_args} --output /dev/null -L -s -w ''%{http_code}'' \"${url}\""

  status=$(eval "${cmd}")

  if [[ $status == "200" ]]; then
    return 0
  else
    # We display the error in the job to allow for better debugging
    curl -L --fail --output /dev/null "${url}"
    echo -e "\nExpected HTTP status 200: received ${status}\n"
    return 1
  fi
}

function section_start () {
  local section_title="${1}"
  local section_description="${2:-$section_title}"

  echo -e "section_start:`date +%s`:${section_title}[collapsed=true]\r\e[0K${section_description}"
}

function section_end () {
  local section_title="${1}"

  echo -e "section_end:`date +%s`:${section_title}\r\e[0K"
}

function bundle_install_script() {
  local extra_install_args="${1}"

  if [[ "${extra_install_args}" =~ "--without" ]]; then
    echoerr "The '--without' flag shouldn't be passed as it would replace the default \${BUNDLE_WITHOUT} (currently set to '${BUNDLE_WITHOUT}')."
    echoerr "Set the 'BUNDLE_WITHOUT' variable instead, e.g. '- export BUNDLE_WITHOUT=\"\${BUNDLE_WITHOUT}:any:other:group:not:to:install\"'."
    exit 1;
  fi;

  section_start "bundle-install" "Installing gems"

  gem --version
  bundle --version
  gem install bundler --no-document --conservative --version 2.4.11
  test -d jh && bundle config set --local gemfile 'jh/Gemfile'
  bundle config set path "$(pwd)/vendor"
  bundle config set clean 'true'

  echo "${BUNDLE_WITHOUT}"
  bundle config

  run_timed_command "bundle install ${BUNDLE_INSTALL_FLAGS} ${extra_install_args}"

  if [[ $(bundle info pg) ]]; then
    # When we test multiple versions of PG in the same pipeline, we have a single `setup-test-env`
    # job but the `pg` gem needs to be rebuilt since it includes extensions (https://guides.rubygems.org/gems-with-extensions).
    # Uncomment the following line if multiple versions of PG are tested in the same pipeline.
    run_timed_command "bundle pristine pg"
  fi

  section_end "bundle-install"
}

function yarn_install_script() {
  section_start "yarn-install" "Installing Yarn packages"

  retry yarn install --frozen-lockfile

  section_end "yarn-install"
}

function assets_compile_script() {
  section_start "assets-compile" "Compiling frontend assets"

  bin/rake gitlab:assets:compile

  section_end "assets-compile"
}

function setup_db_user_only() {
  source scripts/create_postgres_user.sh
}

function setup_db_praefect() {
  createdb -h postgres -U postgres --encoding=UTF8 --echo praefect_test
}

function setup_db() {
  section_start "setup-db" "Setting up DBs"

  setup_db_user_only
  run_timed_command_with_metric "bundle exec rake db:drop db:create db:schema:load db:migrate gitlab:db:lock_writes" "setup_db"
  setup_db_praefect

  section_end "setup-db"
}

function install_gitlab_gem() {
  run_timed_command "gem install httparty --no-document --version 0.20.0"
  run_timed_command "gem install gitlab --no-document --version 4.19.0"
}

function install_tff_gem() {
  run_timed_command "gem install test_file_finder --no-document --version 0.1.4"
}

function install_activesupport_gem() {
  run_timed_command "gem install activesupport --no-document --version 6.1.7.2"
}

function install_junit_merge_gem() {
  run_timed_command "gem install junit_merge --no-document --version 0.1.2"
}

function fail_on_warnings() {
  local cmd="$*"
  local warning_file
  warning_file="$(mktemp)"

  local allowed_warning_file
  allowed_warning_file="$(mktemp)"

  eval "$cmd 2>$warning_file"
  local ret=$?

  # Filter out comments and empty lines from allowed warnings file.
  grep --invert-match --extended-regexp "^#|^$" scripts/allowed_warnings.txt > "$allowed_warning_file"

  local warnings
  # Filter out allowed warnings from stderr.
  # Turn grep errors into warnings so we fail later.
  warnings=$(grep --invert-match --extended-regexp --file "$allowed_warning_file" "$warning_file" 2>&1 || true)

  rm -f "$allowed_warning_file"

  if [ "$warnings" != "" ]
  then
    echoerr "There were warnings:"
    echoerr "======================== Filtered warnings ====================================="
    echo "$warnings" >&2
    echoerr "======================= Unfiltered warnings ===================================="
    cat "$warning_file" >&2
    echoerr "================================================================================"
    rm -f "$warning_file"
    return 1
  fi

  rm -f "$warning_file"

  return $ret
}

function run_timed_command() {
  local cmd="${1}"
  local metric_name="${2:-no}"
  local timed_metric_file
  local start=$(date +%s)

  echosuccess "\$ ${cmd}"
  eval "${cmd}"

  local ret=$?
  local end=$(date +%s)
  local runtime=$((end-start))

  if [[ $ret -eq 0 ]]; then
    echosuccess "==> '${cmd}' succeeded in ${runtime} seconds."

    if [[ "${metric_name}" != "no" ]]; then
      timed_metric_file=$(timed_metric_file $metric_name)
      echo "# TYPE ${metric_name} gauge" > "${timed_metric_file}"
      echo "# UNIT ${metric_name} seconds" >> "${timed_metric_file}"
      echo "${metric_name} ${runtime}" >> "${timed_metric_file}"
    fi

    return 0
  else
    echoerr "==> '${cmd}' failed (${ret}) in ${runtime} seconds."
    return $ret
  fi
}

function run_timed_command_with_metric() {
  local cmd="${1}"
  local metric_name="${2}"
  local metrics_file=${METRICS_FILE:-metrics.txt}

  run_timed_command "${cmd}" "${metric_name}"

  local ret=$?

  cat $(timed_metric_file $metric_name) >> "${metrics_file}"

  return $ret
}

function timed_metric_file() {
  local metric_name="${1}"

  echo "$(pwd)/tmp/duration_${metric_name}.txt"
}

function echoerr() {
  local header="${2:-no}"

  if [ "${header}" != "no" ]; then
    printf "\n\033[0;31m** %s **\n\033[0m" "${1}" >&2;
  else
    printf "\033[0;31m%s\n\033[0m" "${1}" >&2;
  fi
}

function echoinfo() {
  local header="${2:-no}"

  if [ "${header}" != "no" ]; then
    printf "\n\033[0;33m** %s **\n\033[0m" "${1}" >&2;
  else
    printf "\033[0;33m%s\n\033[0m" "${1}" >&2;
  fi
}

function echosuccess() {
  local header="${2:-no}"

  if [ "${header}" != "no" ]; then
    printf "\n\033[0;32m** %s **\n\033[0m" "${1}" >&2;
  else
    printf "\033[0;32m%s\n\033[0m" "${1}" >&2;
  fi
}

function fail_pipeline_early() {
  local dont_interrupt_me_job_id
  dont_interrupt_me_job_id=$(scripts/api/get_job_id.rb --job-query "scope=success" --job-name "dont-interrupt-me")

  if [[ -n "${dont_interrupt_me_job_id}" ]]; then
    echoinfo "This pipeline cannot be interrupted due to \`dont-interrupt-me\` job ${dont_interrupt_me_job_id}"
  else
    echoinfo "Failing pipeline early for fast feedback due to test failures in rspec fail-fast."
    scripts/api/cancel_pipeline.rb
  fi
}

function danger_as_local() {
  # Force danger to skip CI source GitLab and fallback to "local only git repo".
  unset GITLAB_CI
  # We need to base SHA to help danger determine the base commit for this shallow clone.
  bundle exec danger dry_run --fail-on-errors=true --verbose --base="${CI_MERGE_REQUEST_DIFF_BASE_SHA}" --head="${CI_MERGE_REQUEST_SOURCE_BRANCH_SHA:-$CI_COMMIT_SHA}" --dangerfile="${DANGER_DANGERFILE:-Dangerfile}"
}

# We're inlining this function in `.gitlab/ci/package-and-test/main.gitlab-ci.yml` so make sure to reflect any changes there
function assets_image_tag() {
  local cache_assets_hash_file="cached-assets-hash.txt"

  if [[ -n "${CI_COMMIT_TAG}" ]]; then
    echo -n "${CI_COMMIT_REF_NAME}"
  elif [[ -f "${cache_assets_hash_file}" ]]; then
    echo -n "assets-hash-$(cat ${cache_assets_hash_file} | cut -c1-10)"
  else
    echo -n "${CI_COMMIT_SHA}"
  fi
}

function setup_gcloud() {
  gcloud auth activate-service-account --key-file="${REVIEW_APPS_GCP_CREDENTIALS}"
  gcloud config set project "${REVIEW_APPS_GCP_PROJECT}"
}

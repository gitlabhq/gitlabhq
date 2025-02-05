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
    echo "[$(date '+%H:%M:%S')] Retry attempts left: $i..."
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
    echo -e "\n[$(date '+%H:%M:%S')] Curl to $url successful with 200 response"
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
  local collapsed="${3:-true}"

  echo -e "section_start:`date +%s`:${section_title}[collapsed=${collapsed}]\r\e[0K${section_description}"
}

function section_end () {
  local section_title="${1}"

  echo -e "section_end:`date +%s`:${section_title}\r\e[0K"
}

function rspec_section() {
  section_start "rspec" "RSpec" "false"
  "$@"
  section_end "rspec"
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
  test -d jh && bundle config set --local gemfile 'jh/Gemfile'
  bundle config set path "$(pwd)/vendor"
  bundle config set clean 'true'

  echo "${BUNDLE_WITHOUT}"
  bundle config

  run_timed_command "bundle install ${BUNDLE_INSTALL_FLAGS} ${extra_install_args}"

  if [[ $(bundle info pg) ]]; then
    # Bundler will complain about replacing gems in world-writeable directories, so lock down access.
    # This appears to happen when the gems are uncached, since the Runner uses a restrictive umask.
    find vendor -type d -exec chmod 700 {} +
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

function yarn_install_script_storybook() {
  section_start "yarn-install-storybook" "Installing Yarn packages for Storybook"

  retry yarn storybook:install --frozen-lockfile

  section_end "yarn-install-storybook"
}

function assets_compile_script() {
  section_start "assets-compile" "Compiling frontend assets"

  bin/rake gitlab:assets:compile

  section_end "assets-compile"
}

function setup_database_yml() {
  if [ "$DECOMPOSED_DB" == "true" ]; then
    if [ "$SEC_DECOMPOSED_DB" == "true" ]; then
      echo "Using SEC decomposed database config (config/database.yml.decomposed-sec-postgresql)"
      cp config/database.yml.decomposed-sec-postgresql config/database.yml
    else
      echo "Using decomposed database config (config/database.yml.decomposed-postgresql)"
      cp config/database.yml.decomposed-postgresql config/database.yml
    fi
  else
    echo "Using two connections, single database config (config/database.yml.postgresql)"
    cp config/database.yml.postgresql config/database.yml

    if [ "$CI_CONNECTION_DB" != "true" ]; then
      echo "Disabling ci connection in config/database.yml"
      sed -i "/ci:$/, /geo:$/ {s|^|#|;s|#  geo:|  geo:|;}" config/database.yml
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
}

function setup_db_user_only() {
  source scripts/create_postgres_user.sh
}

function setup_db_praefect() {
  createdb -h postgres -U postgres --encoding=UTF8 --echo praefect_test
}

function setup_db() {
  section_start "setup-db" "Setting up DBs"

  if [[ -f pg_dumpall.sql ]] && ! [[ "$DECOMPOSED_DB" =~ "false" ]]; then
    echo "Found pg_dumpall.sql, applying!"

    psql -h postgres -U postgres -q < pg_dumpall.sql > /dev/null
    rm pg_dumpall.sql

    section_end "setup-db"
    return 0
  fi

  if [[ -f pg_dumpall.sql ]]; then
    echo "Found pg_dumpall.sql but we're not using a standard multi-db (decomposed) setup. Performing a regular db setup instead."
    rm pg_dumpall.sql
  fi

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
  run_timed_command "gem install test_file_finder --no-document --version 0.3.1"
}

function install_activesupport_gem() {
  run_timed_command "gem install activesupport --no-document --version 7.0.8.4"
}

function install_junit_merge_gem() {
  run_timed_command "gem install junit_merge --no-document --version 0.1.2"
}

function select_existing_files() {
  ruby -e 'print $stdin.read.split(" ").select { |f| File.exist?(f) }.join(" ")'
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

# We're inlining this function in `.gitlab/ci/test-on-omnibus/main.gitlab-ci.yml` so make sure to reflect any changes there
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

function download_files() {
  base_url_prefix="${CI_API_V4_URL}/projects/${CI_PROJECT_ID}/repository/files"
  base_url_suffix="raw?ref=${CI_COMMIT_SHA}"

  # Construct the list of files to download with curl
  for file in "$@"; do
    local url_encoded_filename
    url_encoded_filename=$(url_encode "${file}")
    local file_url="${base_url_prefix}/${url_encoded_filename}/${base_url_suffix}"
    echo "url = ${file_url}" >> urls_outputs.txt
    echo "output = ${file}" >> urls_outputs.txt
  done

  echo "List of files to download:"
  cat urls_outputs.txt

  curl -f --header "Private-Token: ${PROJECT_TOKEN_FOR_CI_SCRIPTS_API_USAGE}" --create-dirs --parallel --config urls_outputs.txt
}

# Taken from https://gist.github.com/jaytaylor/5a90c49e0976aadfe0726a847ce58736
#
# It is surprisingly hard to url-encode an URL in shell. shorter alternatives used jq,
# but we would then need to install it wherever we would use this no-clone functionality.
#
# For the purposes of url-encoding filenames, this function should be enough.
function url_encode() {
  echo "$@" | sed \
    -e 's/%/%25/g' \
    -e 's/ /%20/g' \
    -e 's/!/%21/g' \
    -e 's/"/%22/g' \
    -e "s/'/%27/g" \
    -e 's/#/%23/g' \
    -e 's/(/%28/g' \
    -e 's/)/%29/g' \
    -e 's/+/%2b/g' \
    -e 's/,/%2c/g' \
    -e 's/-/%2d/g' \
    -e 's/:/%3a/g' \
    -e 's/;/%3b/g' \
    -e 's/?/%3f/g' \
    -e 's/@/%40/g' \
    -e 's/\$/%24/g' \
    -e 's/\&/%26/g' \
    -e 's/\*/%2a/g' \
    -e 's/\./%2e/g' \
    -e 's/\//%2f/g' \
    -e 's/\[/%5b/g' \
    -e 's/\\/%5c/g' \
    -e 's/\]/%5d/g' \
    -e 's/\^/%5e/g' \
    -e 's/_/%5f/g' \
    -e 's/`/%60/g' \
    -e 's/{/%7b/g' \
    -e 's/|/%7c/g' \
    -e 's/}/%7d/g' \
    -e 's/~/%7e/g'
}

# Download the local gems in `gems` and `vendor/gems` folders from the API.
#
# This is useful if you need to run bundle install while not doing a git clone of the gitlab-org/gitlab repo.
function download_local_gems() {
  for folder_path in vendor/gems gems; do
    local output="${folder_path}.tar.gz"

    # From https://docs.gitlab.com/ee/api/repositories.html#get-file-archive:
    #
    #   This endpoint can be accessed without authentication if the repository is publicly accessible.
    #   For GitLab.com users, this endpoint has a rate limit threshold of 5 requests per minute.
    #
    # We don't want to set a token for public repo (e.g. gitlab-org/gitlab), as 5 requests/minute can
    # potentially be reached with many pipelines running in parallel.
    local private_token_header=""
    if [[ "${CI_PROJECT_VISIBILITY}" != "public" ]]; then
      private_token_header="Private-Token: ${PROJECT_TOKEN_FOR_CI_SCRIPTS_API_USAGE}"
    fi

    echo "Downloading ${folder_path}"

    url="${CI_API_V4_URL}/projects/${CI_PROJECT_ID}/repository/archive"
    curl -f \
      --create-dirs \
      --get \
      --header "${private_token_header}" \
      --output "${output}" \
      --data-urlencode "sha=${CI_COMMIT_SHA}" \
      --data-urlencode "path=${folder_path}" \
      "${url}"

    tar -zxf "${output}" --strip-component 1
    rm "${output}"
  done
}

function define_trigger_branch_in_build_env() {
  target_branch_name="${CI_MERGE_REQUEST_TARGET_BRANCH_NAME:-${CI_COMMIT_REF_NAME}}"
  stable_branch_regex="^[0-9-]+-stable(-ee)?$"

  echo "target_branch_name: ${target_branch_name}"

  if [[ $target_branch_name =~ $stable_branch_regex  ]]
  then
    export TRIGGER_BRANCH="${target_branch_name%-ee}"
  else
    export TRIGGER_BRANCH=master
  fi

  if [ -f "$BUILD_ENV" ]; then
    echo "TRIGGER_BRANCH=${TRIGGER_BRANCH}" >> $BUILD_ENV
  fi
}

function log_disk_usage() {
  local exit_on_low_space="${1:-false}"
  local space_threshold_gb=2 # 2GB

  available_space=$(df -h | awk 'NR==2 {print $4}') # value at the 2nd row 4th column of the df -h output

  echo "*******************************************************"
  echo "This runner currently has ${available_space} free disk space."
  echo "*******************************************************"

  section_start "log_disk_usage" "Disk usage detail" "true"
  echo -e "df -h"
  df -h

  echo -e "du -h -d 1"
  du -h -d 1
  section_end "log_disk_usage"

  if [[ "$exit_on_low_space" = "true" ]]; then

    if [[ $OSTYPE == 'darwin'* ]]; then
      available_space_gb=$(df -g | awk 'NR==2 {print $4}')
    else
      available_space_gb=$(df -BG | awk 'NR==2 {print $4}' | sed 's/G//')
    fi

    if (( $(echo "$available_space_gb < $space_threshold_gb") )); then
      echo "********************************************************************"
      echo "This job requires ${space_threshold_gb}G free disk space, but the runner only has ${available_space}."
      echo "Exiting now in anticipation of a 'no space left on device' error."
      echo "If this problem persists, please contact #g_hosted_runners team."
      echo "NOTE: This job will be retried automatically."
      echo "********************************************************************"

      exit_code=111
      alert_job_in_slack $exit_code "Auto-retried due to low free disk space."

      exit $exit_code
    fi
  fi
}

# all functions below are for customizing CI job exit code
function run_with_custom_exit_code() {
  set +e # temprorarily disable exit on error to prevent premature exit

  # runs command passed in as argument, save standard error and standard output
  output=$("$@" 2>&1)
  initial_exit_code=$?

  local trace_file="stdout_stderr_log.out"

  echo "$output" | tee "$trace_file"

  find_custom_exit_code "$initial_exit_code" "$trace_file"
  new_exit_code=$?

  echo "new_exit_code=$new_exit_code"
  set -e

  exit "$new_exit_code"
}

function find_custom_exit_code() {
  local exit_code="$1"
  local trace_file="$2"

  # Early return if exit code is 0
  [ "$exit_code" -eq 0 ] && return 0

  # Check if trace_file is set
  if [ -z "$trace_file" ] || [ ! -f "$trace_file" ]; then
      echoerr "$trace_file is not set or file does not exist"
      exit "$exit_code"
  fi

  if grep -i -q \
    -e "Failed to connect to 127.0.0.1" \
    -e "Failed to open TCP connection to" \
    -e "connection reset by peer" "$trace_file"; then

    echoerr "Detected network connection error. Changing exit code to 110."
    exit_code=110
    alert_job_in_slack "$exit_code" "Network connection error"

  elif grep -i -q -e "no space left on device" "$trace_file"; then
    echoerr "Detected no space left on device. Changing exit code to 111."
    exit_code=111
    alert_job_in_slack "$exit_code" "Low disk space"

  elif grep -i -q \
    -e "error: downloading artifacts from coordinator" \
    -e "error: uploading artifacts as \"archive\" to coordinator" "$trace_file"; then
    echoerr "Detected artifact transit error. Changing exit code to 160."
    exit_code=160
    alert_job_in_slack "$exit_code" "Artifact transit error"

  elif grep -i -q \
    -e "500 Internal Server Error" \
    -e "Internal Server Error 500" \
    -e "502 Bad Gateway" \
    -e "503 Service Unavailable" "$trace_file"; then
    echoerr "Detected 5XX error. Changing exit code to 161."
    exit_code=161
    alert_job_in_slack "$exit_code" "5XX error"

  elif grep -i -q -e "gitaly spawn failed" "$trace_file"; then
    echoerr "Detected gitaly spawn failure error. Changing exit code to 162."
    exit_code=162
    alert_job_in_slack "$exit_code" "Gitaly spawn failure"

  elif grep -i -q -e \
    "Rspec suite is exceeding the 80 minute limit and is forced to exit with error" "$trace_file"; then
    echoerr "Detected rspec timeout risk. Changing exit code to 163."
    exit_code=163
    alert_job_in_slack "$exit_code" "RSpec taking longer than 80 minutes and forced to fail."

  elif grep -i -q \
    -e "Redis client could not fetch cluster information: Connection refused" \
    -e "Redis::Cluster::CommandErrorCollection" \
    -e "CLUSTERDOWN The cluster is down" "$trace_file"; then
    echoerr "Detected Redis cluster error. Changing exit code to 164."
    exit_code=164
    alert_job_in_slack "$exit_code" "Redis cluster error"

  elif grep -i -q -e "segmentation fault" "$trace_file"; then
    echoerr "Detected segmentation fault. Changing exit code to 165."
    exit_code=165
    alert_job_in_slack "$exit_code" "Segmentation fault"

  elif grep -i -q -e "Error: EEXIST: file already exists" "$trace_file"; then
    echoerr "Detected EEXIST error. Changing exit code to 166."
    exit_code=166
    alert_job_in_slack "$exit_code" "EEXIST: file already exists"

  elif grep -i -q -e \
    "fatal: remote error: GitLab is currently unable to handle this request due to load" "$trace_file"; then
    echoerr "Detected GitLab overload error in job trace. Changing exit code to 167."
    exit_code=167
    alert_job_in_slack "$exit_code" "gitlab.com overload"

  else
    echoinfo "not changing exit code"
  fi

  echoinfo "will exit with $exit_code"
  return "$exit_code"
}

function alert_job_in_slack() {
  local exit_code=$1
  local alert_reason=$2
  local slack_channel="#dx_development-analytics_alerts"

  echoinfo "Reporting ${CI_JOB_URL} to Slack channel ${slack_channel}"

  json_payload=$(cat <<JSON
{
	"blocks": [
		{
			"type": "section",
			"text": {
				"type": "mrkdwn",
				"text": "*<${CI_PROJECT_URL}|${CI_PROJECT_PATH}> pipeline <${CI_PIPELINE_URL}|#${CI_PIPELINE_ID}> needs attention*"
			}
		},
		{
			"type": "section",
			"fields": [
				{
					"type": "mrkdwn",
					"text": "*Branch:* \n\`${CI_COMMIT_REF_NAME}\`"
				},
				{
					"type": "mrkdwn",
					"text": "*Job:* \n<${CI_JOB_URL}|${CI_JOB_NAME}>"
				},
				{
					"type": "mrkdwn",
					"text": "*Error code:* \n\`${exit_code}\`"
				},
				{
					"type": "mrkdwn",
					"text": "*Reason:* \n${alert_reason}"
				}
			]
		}
	],
  "channel": "${slack_channel}"
}
JSON
)

  curl --silent -o /dev/null -X POST "${CI_SLACK_WEBHOOK_URL}" \
    -H 'Content-type: application/json' \
    -d "${json_payload}"
}

function retry() {
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

function setup_db_user_only() {
  source scripts/create_postgres_user.sh
}

function setup_db() {
  run_timed_command "setup_db_user_only"
  run_timed_command "bundle exec rake db:drop db:create db:structure:load db:migrate gitlab:db:setup_ee"
}

function install_api_client_dependencies_with_apk() {
  apk add --update openssl curl jq
}

function install_api_client_dependencies_with_apt() {
  apt update && apt install jq -y
}

function install_gitlab_gem() {
  gem install httparty --no-document --version 0.18.1
  gem install gitlab --no-document --version 4.14.1
}

function install_tff_gem() {
  gem install test_file_finder --version 0.1.0
}

function run_timed_command() {
  local cmd="${1}"
  local start=$(date +%s)
  echosuccess "\$ ${cmd}"
  eval "${cmd}"
  local ret=$?
  local end=$(date +%s)
  local runtime=$((end-start))

  if [[ $ret -eq 0 ]]; then
    echosuccess "==> '${cmd}' succeeded in ${runtime} seconds."
    return 0
  else
    echoerr "==> '${cmd}' failed (${ret}) in ${runtime} seconds."
    return $ret
  fi
}

function echoerr() {
  local header="${2}"

  if [ -n "${header}" ]; then
    printf "\n\033[0;31m** %s **\n\033[0m" "${1}" >&2;
  else
    printf "\033[0;31m%s\n\033[0m" "${1}" >&2;
  fi
}

function echoinfo() {
  local header="${2}"

  if [ -n "${header}" ]; then
    printf "\n\033[0;33m** %s **\n\033[0m" "${1}" >&2;
  else
    printf "\033[0;33m%s\n\033[0m" "${1}" >&2;
  fi
}

function echosuccess() {
  local header="${2}"

  if [ -n "${header}" ]; then
    printf "\n\033[0;32m** %s **\n\033[0m" "${1}" >&2;
  else
    printf "\033[0;32m%s\n\033[0m" "${1}" >&2;
  fi
}

function fail_pipeline_early() {
  local dont_interrupt_me_job_id
  dont_interrupt_me_job_id=$(scripts/api/get_job_id --job-query "scope=success" --job-name "dont-interrupt-me")

  if [[ -n "${dont_interrupt_me_job_id}" ]]; then
    echoinfo "This pipeline cannot be interrupted due to \`dont-interrupt-me\` job ${dont_interrupt_me_job_id}"
  else
    echoinfo "Failing pipeline early for fast feedback due to test failures in rspec fail-fast."
    scripts/api/cancel_pipeline
  fi
}

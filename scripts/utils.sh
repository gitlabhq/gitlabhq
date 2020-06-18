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
  gem install httparty --no-document --version 0.17.3
  gem install gitlab --no-document --version 4.13.0
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

function get_job_id() {
  local job_name="${1}"
  local query_string="${2:+&${2}}"
  local api_token="${API_TOKEN-${GITLAB_BOT_MULTI_PROJECT_PIPELINE_POLLING_TOKEN}}"
  if [ -z "${api_token}" ]; then
    echoerr "Please provide an API token with \$API_TOKEN or \$GITLAB_BOT_MULTI_PROJECT_PIPELINE_POLLING_TOKEN."
    return
  fi

  local max_page=3
  local page=1

  while true; do
    local url="https://gitlab.com/api/v4/projects/${CI_PROJECT_ID}/pipelines/${CI_PIPELINE_ID}/jobs?per_page=100&page=${page}${query_string}"
    echoinfo "GET ${url}"

    local job_id
    job_id=$(curl --silent --show-error --header "PRIVATE-TOKEN: ${api_token}" "${url}" | jq "map(select(.name == \"${job_name}\")) | map(.id) | last")
    [[ "${job_id}" == "null" && "${page}" -lt "$max_page" ]] || break

    let "page++"
  done

  if [[ "${job_id}" == "" ]]; then
    echoerr "The '${job_name}' job ID couldn't be retrieved!"
  else
    echoinfo "The '${job_name}' job ID is ${job_id}"
    echo "${job_id}"
  fi
}

function play_job() {
  local job_name="${1}"
  local job_id
  job_id=$(get_job_id "${job_name}" "scope=manual");
  if [ -z "${job_id}" ]; then return; fi

  local api_token="${API_TOKEN-${GITLAB_BOT_MULTI_PROJECT_PIPELINE_POLLING_TOKEN}}"
  if [ -z "${api_token}" ]; then
    echoerr "Please provide an API token with \$API_TOKEN or \$GITLAB_BOT_MULTI_PROJECT_PIPELINE_POLLING_TOKEN."
    return
  fi

  local url="https://gitlab.com/api/v4/projects/${CI_PROJECT_ID}/jobs/${job_id}/play"
  echoinfo "POST ${url}"

  local job_url
  job_url=$(curl --silent --show-error --request POST --header "PRIVATE-TOKEN: ${api_token}" "${url}" | jq ".web_url")
  echoinfo "Manual job '${job_name}' started at: ${job_url}"
}

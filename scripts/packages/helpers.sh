#!/usr/bin/env bash

source scripts/utils.sh

function archive_doesnt_exist() {
  local package_url="${1}"

  echoinfo "Downloading archive at ${package_url}..."

  status=$(curl -I --silent --retry 3 --output /dev/null -w "%{http_code}" "${package_url}")

  if [[ "${status}" = "200" ]]; then
    echoinfo "The archive was found. The server returned status ${status}."
    return 1
  else
    echoinfo "The archive was not found. The server returned status ${status}."
    return 0
  fi
}

function create_package() {
  local archive_filename="${1}"
  local paths_to_archive="${2}"
  local tar_working_folder="${3:-.}"

  echoinfo "Running 'tar -czvf ${archive_filename} -C ${tar_working_folder} ${paths_to_archive}'"
  tar -czf ${archive_filename} -C ${tar_working_folder} ${paths_to_archive}
  du -h ${archive_filename}
}

function upload_package() {
  local archive_filename="${1}"
  local package_url="${2}"
  local token_header="${CURL_TOKEN_HEADER}"
  local token="${CI_JOB_TOKEN}"

  if [[ "${UPLOAD_PACKAGE_FLAG}" = "false" ]]; then
    echoerr "The archive ${archive_filename} isn't supposed to be uploaded for this instance (${CI_SERVER_HOST}) & project (${CI_PROJECT_PATH})!"
    exit 1
  fi

  echoinfo "Uploading ${archive_filename} to ${package_url} ..."
  curl --fail --silent --retry 3 --header "${token_header}: ${token}" --upload-file "${archive_filename}" "${package_url}"
}

function read_curl_package() {
  local package_url="${1}"

  echoinfo "Downloading from ${package_url} ..."

  curl --fail --silent --retry 3 "${package_url}"
}

function extract_package() {
  local tar_working_folder="${1:-.}"
  mkdir -p "${tar_working_folder}"

  echoinfo "Extracting archive to ${tar_working_folder}"

  tar -xz -C ${tar_working_folder} < /dev/stdin
}

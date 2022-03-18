#!/usr/bin/env bash

set -euo pipefail

export CURL_TOKEN_HEADER="${CURL_TOKEN_HEADER:-"JOB-TOKEN"}"
export GITLAB_WORKHORSE_BINARIES_LIST="gitlab-resize-image gitlab-zip-cat gitlab-zip-metadata gitlab-workhorse"
export GITLAB_WORKHORSE_PACKAGE_FILES_LIST="${GITLAB_WORKHORSE_BINARIES_LIST} WORKHORSE_TREE"
export GITLAB_WORKHORSE_TREE=${GITLAB_WORKHORSE_TREE:-$(git rev-parse HEAD:workhorse)}
export GITLAB_WORKHORSE_PACKAGE="workhorse-${GITLAB_WORKHORSE_TREE}.tar.gz"
export GITLAB_WORKHORSE_PACKAGE_URL="${CI_API_V4_URL}/projects/${CI_PROJECT_ID}/packages/generic/${GITLAB_WORKHORSE_FOLDER}/${GITLAB_WORKHORSE_TREE}/${GITLAB_WORKHORSE_PACKAGE}"

function gitlab_workhorse_archive_doesnt_exist() {
  local package_url="${GITLAB_WORKHORSE_PACKAGE_URL}"

  status=$(curl -I --silent --retry 3 --output /dev/null -w "%{http_code}" "${package_url}")

  [[ "${status}" != "200" ]]
}

function create_gitlab_workhorse_package() {
  local archive_filename="${GITLAB_WORKHORSE_PACKAGE}"
  local folder_to_archive="${GITLAB_WORKHORSE_FOLDER}"
  local workhorse_folder_path="${TMP_TEST_GITLAB_WORKHORSE_PATH}"
  local tar_working_folder="${TMP_TEST_FOLDER}"

  echoinfo "Running 'tar -czvf ${archive_filename} -C ${tar_working_folder} ${folder_to_archive}'"
  tar -czvf ${archive_filename} -C ${tar_working_folder} ${folder_to_archive}
  du -h ${archive_filename}
}

function extract_gitlab_workhorse_package() {
  local tar_working_folder="${TMP_TEST_FOLDER}"

  echoinfo "Extracting archive to ${tar_working_folder}"

  tar -xzv -C ${tar_working_folder} < /dev/stdin
}

function upload_gitlab_workhorse_package() {
  local archive_filename="${GITLAB_WORKHORSE_PACKAGE}"
  local package_url="${GITLAB_WORKHORSE_PACKAGE_URL}"
  local token_header="${CURL_TOKEN_HEADER}"
  local token="${CI_JOB_TOKEN}"

  echoinfo "Uploading ${archive_filename} to ${package_url} ..."
  curl --fail --silent --retry 3 --header "${token_header}: ${token}" --upload-file "${archive_filename}" "${package_url}"
}

function read_curl_gitlab_workhorse_package() {
  local package_url="${GITLAB_WORKHORSE_PACKAGE_URL}"
  local token_header="${CURL_TOKEN_HEADER}"
  local token="${CI_JOB_TOKEN}"

  echoinfo "Downloading from ${package_url} ..."

  curl --fail --silent --retry 3 --header "${token_header}: ${token}" "${package_url}"
}

function download_and_extract_gitlab_workhorse_package() {
  read_curl_gitlab_workhorse_package | extract_gitlab_workhorse_package
}

function select_gitlab_workhorse_essentials() {
  local tmp_path="${CI_PROJECT_DIR}/tmp/${GITLAB_WORKHORSE_FOLDER}"
  local original_gitlab_workhorse_path="${TMP_TEST_GITLAB_WORKHORSE_PATH}"

  mkdir -p ${tmp_path}
  cd ${original_gitlab_workhorse_path} && mv ${GITLAB_WORKHORSE_PACKAGE_FILES_LIST} ${tmp_path} && cd -
  rm -rf ${original_gitlab_workhorse_path}

  # Move the temp folder to its final destination
  mv ${tmp_path} ${TMP_TEST_FOLDER}
}

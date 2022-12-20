#!/usr/bin/env bash

set -euo pipefail

export CURL_TOKEN_HEADER="${CURL_TOKEN_HEADER:-"JOB-TOKEN"}"

export GITLAB_COM_CANONICAL_PROJECT_ID="278964" # https://gitlab.com/gitlab-org/gitlab
export JIHULAB_COM_CANONICAL_PROJECT_ID="13953" # https://jihulab.com/gitlab-cn/gitlab
export CANONICAL_PROJECT_ID="${GITLAB_COM_CANONICAL_PROJECT_ID}"

# By default, we only want to store/retrieve packages from GitLab.com...
export API_V4_URL="https://gitlab.com/api/v4"

# Unless we're in the JiHu project, which needs to use its own package registry
if [[ "${CI_SERVER_HOST}" = "jihulab.com" ]]; then
  export API_V4_URL="${CI_API_V4_URL}"
  export CANONICAL_PROJECT_ID="${JIHULAB_COM_CANONICAL_PROJECT_ID}"
fi

export API_PACKAGES_BASE_URL="${API_V4_URL}/projects/${CANONICAL_PROJECT_ID}/packages/generic"

export UPLOAD_TO_CURRENT_SERVER="false"
# We only want to upload artifacts to https://gitlab.com and https://jihulab.com instances
if [[ "${CI_SERVER_HOST}" = "gitlab.com" ]] || [[ "${CI_SERVER_HOST}" = "jihulab.com" ]]; then
  export UPLOAD_TO_CURRENT_SERVER="true"
fi

export UPLOAD_PACKAGE_FLAG="false"
# And only if we're in a pipeline from the canonical project
if [[ "${UPLOAD_TO_CURRENT_SERVER}" = "true" ]] && [[ "${CI_PROJECT_ID}" = "${CANONICAL_PROJECT_ID}" ]]; then
  export UPLOAD_PACKAGE_FLAG="true"
fi

# Workhorse constants
export GITLAB_WORKHORSE_BINARIES_LIST="gitlab-resize-image gitlab-zip-cat gitlab-zip-metadata gitlab-workhorse"
export GITLAB_WORKHORSE_PACKAGE_FILES_LIST="${GITLAB_WORKHORSE_BINARIES_LIST} WORKHORSE_TREE"
export GITLAB_WORKHORSE_TREE=${GITLAB_WORKHORSE_TREE:-$(git rev-parse HEAD:workhorse)}
export GITLAB_WORKHORSE_PACKAGE="workhorse-${GITLAB_WORKHORSE_TREE}.tar.gz"
export GITLAB_WORKHORSE_PACKAGE_URL="${API_PACKAGES_BASE_URL}/${GITLAB_WORKHORSE_FOLDER}/${GITLAB_WORKHORSE_TREE}/${GITLAB_WORKHORSE_PACKAGE}"

# Assets constants
export GITLAB_ASSETS_PATHS_LIST="cached-assets-hash.txt app/assets/javascripts/locale/**/app.js public/assets/"
export GITLAB_ASSETS_PACKAGE_VERSION="v2" # bump this version each time GITLAB_ASSETS_PATHS_LIST is changed

export GITLAB_EDITION="ee"
if [[ "${FOSS_ONLY:-no}" = "1" ]] || [[ "${CI_PROJECT_NAME}" = "gitlab-foss" ]]; then
  export GITLAB_EDITION="foss"
fi

export GITLAB_ASSETS_HASH="${GITLAB_ASSETS_HASH:-"NO_HASH"}"
export GITLAB_ASSETS_PACKAGE="assets-${NODE_ENV}-${GITLAB_EDITION}-${GITLAB_ASSETS_HASH}-${GITLAB_ASSETS_PACKAGE_VERSION}.tar.gz"
export GITLAB_ASSETS_PACKAGE_URL="${API_PACKAGES_BASE_URL}/assets/${NODE_ENV}-${GITLAB_EDITION}-${GITLAB_ASSETS_HASH}/${GITLAB_ASSETS_PACKAGE}"

# Generic helper functions
function archive_doesnt_exist() {
  local package_url="${1}"

  status=$(curl -I --silent --retry 3 --output /dev/null -w "%{http_code}" "${package_url}")

  [[ "${status}" != "200" ]]
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

# Workhorse functions
function gitlab_workhorse_archive_doesnt_exist() {
  archive_doesnt_exist "${GITLAB_WORKHORSE_PACKAGE_URL}"
}

function create_gitlab_workhorse_package() {
  create_package "${GITLAB_WORKHORSE_PACKAGE}" "${GITLAB_WORKHORSE_FOLDER}" "${TMP_TEST_FOLDER}"
}

function upload_gitlab_workhorse_package() {
  upload_package "${GITLAB_WORKHORSE_PACKAGE}" "${GITLAB_WORKHORSE_PACKAGE_URL}"
}

function download_and_extract_gitlab_workhorse_package() {
  read_curl_package "${GITLAB_WORKHORSE_PACKAGE_URL}" | extract_package "${TMP_TEST_FOLDER}"
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

# Assets functions
function gitlab_assets_archive_doesnt_exist() {
  archive_doesnt_exist "${GITLAB_ASSETS_PACKAGE_URL}"
}

function download_and_extract_gitlab_assets() {
  read_curl_package "${GITLAB_ASSETS_PACKAGE_URL}" | extract_package
}

function create_gitlab_assets_package() {
  create_package "${GITLAB_ASSETS_PACKAGE}" "${GITLAB_ASSETS_PATHS_LIST}"
}

function upload_gitlab_assets_package() {
  upload_package "${GITLAB_ASSETS_PACKAGE}" "${GITLAB_ASSETS_PACKAGE_URL}"
}

#!/usr/bin/env bash

set -euo pipefail

# Generic helper functions for archives/packages
source scripts/packages/helpers.sh

export CURL_TOKEN_HEADER="${CURL_TOKEN_HEADER:-"JOB-TOKEN"}"

export GITLAB_COM_CANONICAL_PROJECT_ID="278964" # https://gitlab.com/gitlab-org/gitlab
export GITLAB_COM_CANONICAL_FOSS_PROJECT_ID="13083" # https://gitlab.com/gitlab-org/gitlab-foss
export JIHULAB_COM_CANONICAL_PROJECT_ID="13953" # https://jihulab.com/gitlab-cn/gitlab
export CANONICAL_PROJECT_ID="${GITLAB_COM_CANONICAL_PROJECT_ID}"

# By default, we only want to store/retrieve packages from GitLab.com...
export API_V4_URL="https://gitlab.com/api/v4"

# If it's a FOSS repository, it needs to use FOSS package registry
if [[ ! -d "ee/" ]]; then
  export CANONICAL_PROJECT_ID="${GITLAB_COM_CANONICAL_FOSS_PROJECT_ID}"
fi

# If it's in the JiHu project, it needs to use its own package registry
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

# Graphql Schema dump constants
export GRAPHQL_SCHEMA_PACKAGE="graphql-schema.tar.gz"
export GRAPHQL_SCHEMA_PATH="tmp/tests/graphql/"
export GRAPHQL_SCHEMA_PACKAGE_URL="${API_PACKAGES_BASE_URL}/graphql-schema/master/${GRAPHQL_SCHEMA_PACKAGE}"

# Assets constants
export GITLAB_ASSETS_PATHS_LIST="cached-assets-hash.txt app/assets/javascripts/locale/**/app.js public/assets/"
export GITLAB_ASSETS_PACKAGE_VERSION="v2" # bump this version each time GITLAB_ASSETS_PATHS_LIST is changed

export GITLAB_EDITION="ee"
if [[ "${FOSS_ONLY:-no}" = "1" ]] || [[ "${CI_PROJECT_NAME}" = "gitlab-foss" ]]; then
  export GITLAB_EDITION="foss"
fi

if [[ "${CI_SERVER_HOST}" = "jihulab.com" ]]; then
  export GITLAB_EDITION="jh"
fi

export GITLAB_ASSETS_HASH="${GITLAB_ASSETS_HASH:-"NO_HASH"}"
export GITLAB_ASSETS_PACKAGE="assets-${NODE_ENV}-${GITLAB_EDITION}-${GITLAB_ASSETS_HASH}-${GITLAB_ASSETS_PACKAGE_VERSION}.tar.gz"
export GITLAB_ASSETS_PACKAGE_URL="${API_PACKAGES_BASE_URL}/assets/${NODE_ENV}-${GITLAB_EDITION}-${GITLAB_ASSETS_HASH}/${GITLAB_ASSETS_PACKAGE}"

# Fixtures constants
export FIXTURES_PATH="tmp/tests/frontend/**/*"
export REUSE_FRONTEND_FIXTURES_ENABLED="${REUSE_FRONTEND_FIXTURES_ENABLED:-"true"}"

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

function strip_executable_binaries() {
  local path="$1"

  find "$path" -executable -type f ! -size 0 -print0 | xargs -0 grep -IL . | xargs strip || true
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

# Fixtures functions
function check_fixtures_download() {
  if [[ "${REUSE_FRONTEND_FIXTURES_ENABLED}" != "true" ]]; then
    echoinfo "INFO: Reusing frontend fixtures is disabled due to REUSE_FRONTEND_FIXTURES_ENABLED=${REUSE_FRONTEND_FIXTURES_ENABLED}."
    return 1
  fi

  if [[ "${CI_PROJECT_NAME}" != "gitlab" ]] || [[ "${CI_JOB_NAME}" =~ "foss" ]]; then
    echoinfo "INFO: Reusing frontend fixtures is only supported in EE."
    return 1
  fi

  if [[ -z "${CI_MERGE_REQUEST_IID:-}" ]]; then
    return 1
  else
    if tooling/bin/find_only_allowed_files_changes && ! fixtures_archive_doesnt_exist; then
      return 0
    else
      return 1
    fi
  fi
}

function check_fixtures_reuse() {
  if [[ "${REUSE_FRONTEND_FIXTURES_ENABLED}" != "true" ]]; then
    echoinfo "INFO: Reusing frontend fixtures is disabled due to REUSE_FRONTEND_FIXTURES_ENABLED=${REUSE_FRONTEND_FIXTURES_ENABLED}."
    rm -rf "tmp/tests/frontend";
    return 1
  fi

  if [[ "${CI_PROJECT_NAME}" != "gitlab" ]] || [[ "${CI_JOB_NAME}" =~ "foss" ]]; then
    echoinfo "INFO: Reusing frontend fixtures is only supported in EE."
    rm -rf "tmp/tests/frontend";
    return 1
  fi

  if [[ -d "tmp/tests/frontend" ]]; then
    # Remove tmp/tests/frontend/ except on the first parallelized job so that depending
    # jobs don't download the exact same artifact multiple times.
    if [[ -n "${CI_NODE_INDEX:-}" ]] && [[ "${CI_NODE_INDEX:-}" -ne 1 ]]; then
      echoinfo "INFO: Removing 'tmp/tests/frontend' as we're on node ${CI_NODE_INDEX:-}. Dependent jobs will use the artifacts from the first parallelized job.";
      rm -rf "tmp/tests/frontend";
    fi
    return 0
  else
    echoinfo "INFO: 'tmp/tests/frontend' does not exist.";
    return 1
  fi
}

function create_fixtures_package() {
  create_package "${FIXTURES_PACKAGE}" "${FIXTURES_PATH}"
}

function create_and_upload_graphql_schema_package() {
  create_package "${GRAPHQL_SCHEMA_PACKAGE}" "${GRAPHQL_SCHEMA_PATH}"
  upload_package "${GRAPHQL_SCHEMA_PACKAGE}" "${GRAPHQL_SCHEMA_PACKAGE_URL}"
}

function download_and_extract_fixtures() {
  read_curl_package "${FIXTURES_PACKAGE_URL}" | extract_package
}

function export_fixtures_package_variables() {
  export FIXTURES_PACKAGE="fixtures-${FIXTURES_SHA}.tar.gz"
  export FIXTURES_PACKAGE_URL="${API_PACKAGES_BASE_URL}/fixtures/${FIXTURES_SHA}/${FIXTURES_PACKAGE}"
}

function export_fixtures_sha_for_download() {
  export FIXTURES_SHA="${CI_MERGE_REQUEST_TARGET_BRANCH_SHA:-${CI_MERGE_REQUEST_DIFF_BASE_SHA:-$CI_COMMIT_SHA}}"
  export_fixtures_package_variables
}

function export_fixtures_sha_for_upload() {
  export FIXTURES_SHA="${CI_MERGE_REQUEST_SOURCE_BRANCH_SHA:-$CI_COMMIT_SHA}"
  export_fixtures_package_variables
}

function fixtures_archive_doesnt_exist() {
  echoinfo "Checking if the package is available at ${FIXTURES_PACKAGE_URL} ..."

  archive_doesnt_exist "${FIXTURES_PACKAGE_URL}"
}

function fixtures_directory_exists() {
  local fixtures_directory="tmp/tests/frontend/"

  if [[ -d "${fixtures_directory}" ]]; then
    echo "${fixtures_directory} directory exists"
    return 0
  else
    echo "${fixtures_directory} directory does not exist"
    return 1
  fi
}

function upload_fixtures_package() {
  upload_package "${FIXTURES_PACKAGE}" "${FIXTURES_PACKAGE_URL}"
}

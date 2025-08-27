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

# Graphql Schema dump constants
export GRAPHQL_SCHEMA_PACKAGE="graphql-schema.tar.gz"
export GRAPHQL_SCHEMA_PATH="tmp/tests/graphql/"
export GRAPHQL_SCHEMA_PACKAGE_URL="${API_PACKAGES_BASE_URL}/graphql-schema/master/${GRAPHQL_SCHEMA_PACKAGE}"

export GITLAB_EDITION="ee"
if [[ "${FOSS_ONLY:-no}" = "1" ]] || [[ "${CI_PROJECT_NAME}" = "gitlab-foss" ]]; then
  export GITLAB_EDITION="foss"
fi

if [[ "${CI_SERVER_HOST}" = "jihulab.com" ]]; then
  export GITLAB_EDITION="jh"
fi

# Fixtures constants
export FIXTURES_PATH="tmp/tests/frontend/**/*"
export FIXTURES_PACKAGE="fixtures-${GLCI_FIXTURES_HASH:-$CI_COMMIT_SHA}.tar.gz"
export FIXTURES_PACKAGE_URL="${API_PACKAGES_BASE_URL}/fixtures/${GLCI_FIXTURES_HASH:-$CI_COMMIT_SHA}/${FIXTURES_PACKAGE}"

function setup_test_env() {
  mkdir -p ${GLCI_CACHED_SERVICES_FOLDER} ${TMP_TEST_FOLDER}

  # move binaries from cache location to tmp test folder
  echo "Moving cached binaries to '${TMP_TEST_FOLDER}'"
  mv ${GLCI_CACHED_SERVICES_FOLDER}/* ${TMP_TEST_FOLDER}/ && echo "done!" || true

  section_start "setup-test-env" "Setting up testing environment"; scripts/setup-test-env; section_end "setup-test-env";
  section_start "gitaly-test-build" "Compiling Gitaly binaries"; scripts/gitaly-test-build; section_end "gitaly-test-build";  # Do not use 'bundle exec' here

  # restore binaries cache folder before stripping binaries to avoid cache re-upload
  echo "Restoring binaries cache folder"
  mv ${TMP_TEST_FOLDER}/* ${GLCI_CACHED_SERVICES_FOLDER}/
  # remove workhorse config_path file which is recreated on every run and taints cache
  rm -f ${GLCI_CACHED_SERVICES_FOLDER}/gitlab-workhorse/config_path
  # remove testdata folder which taints cache and causes re-upload
  rm -rf ${GLCI_CACHED_SERVICES_FOLDER}/gitaly/internal/testhelper/testdata
  # copy all files to be saved as artifacts
  cp -r ${GLCI_CACHED_SERVICES_FOLDER}/* ${TMP_TEST_FOLDER}/
  echo "done!"

  strip_executable_binaries "${TMP_TEST_FOLDER}"
}

function strip_executable_binaries() {
  local path="$1"

  echo "Stripping executable binaries for size reduction"
  find "$path" -executable -type f ! -size 0 -print0 | xargs -0 grep -IL . | xargs strip || true
  echo "done!"
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

function create_and_upload_graphql_schema_package() {
  create_package "${GRAPHQL_SCHEMA_PACKAGE}" "${GRAPHQL_SCHEMA_PATH}"
  upload_package "${GRAPHQL_SCHEMA_PACKAGE}" "${GRAPHQL_SCHEMA_PACKAGE_URL}"
}

function fixtures_archive_doesnt_exist() {
  echoinfo "Checking if the package is available at ${FIXTURES_PACKAGE_URL} ..."

  archive_doesnt_exist "${FIXTURES_PACKAGE_URL}"
}

function create_fixtures_package() {
  create_package "${FIXTURES_PACKAGE}" "${FIXTURES_PATH}"
}

function upload_fixtures_package() {
  upload_package "${FIXTURES_PACKAGE}" "${FIXTURES_PACKAGE_URL}"
}

# Dump auto-explain logs fingerprints
export FINGERPRINTS_PACKAGE="query-fingerprints.tar.gz"
export FINGERPRINTS_FILE="query_fingerprints.txt"
export FINGERPRINTS_PACKAGE_URL="${API_PACKAGES_BASE_URL}/auto-explain-logs/master/${FINGERPRINTS_PACKAGE}"

function extract_and_upload_fingerprints() {
  echo "Extracting SQL query fingerprints from ${RSPEC_AUTO_EXPLAIN_LOG_PATH}"
  ruby scripts/sql_fingerprint_extractor.rb "${RSPEC_AUTO_EXPLAIN_LOG_PATH}" "${FINGERPRINTS_FILE}.new"

  # Check if any new fingerprints were found
  new_count=$(wc -l < "${FINGERPRINTS_FILE}.new")
  if [ "$new_count" -eq 0 ]; then
    echo "No fingerprints found in current run, exiting early"
    rm "${FINGERPRINTS_FILE}.new"
    return 0
  fi

  echo "Found ${new_count} fingerprints in current run"

  # Attempt to download the previous package directly
  echo "Attempting to download previous fingerprints package..."
  if curl -s -f "${FINGERPRINTS_PACKAGE_URL}" -o latest_fingerprints.tar.gz; then
    echo "Previous fingerprints package downloaded successfully"

    # Extract the package
    mkdir -p temp_fingerprints
    if tar -xzf latest_fingerprints.tar.gz -C temp_fingerprints; then

      if [ -f "temp_fingerprints/${FINGERPRINTS_FILE}" ]; then
        echo "Merging with existing fingerprints..."
        # Combine both files and remove duplicates
        cat "temp_fingerprints/${FINGERPRINTS_FILE}" "${FINGERPRINTS_FILE}.new" | sort | uniq > "${FINGERPRINTS_FILE}"

        # Count and report stats
        old_count=$(wc -l < "temp_fingerprints/${FINGERPRINTS_FILE}")
        new_total=$(wc -l < "${FINGERPRINTS_FILE}")
        added_count=$((new_total - old_count))

        if [ "$added_count" -eq 0 ]; then
          echo "No new unique fingerprints found, exiting early"
          rm -rf temp_fingerprints latest_fingerprints.tar.gz "${FINGERPRINTS_FILE}.new" "${FINGERPRINTS_FILE}"
          return 0
        fi

        echo "Previous fingerprints: ${old_count}"
        echo "Newly added fingerprints: ${added_count}"
        echo "Total unique fingerprints: ${new_total}"
      else
        echo "No fingerprints file found in package, using new ones only"
        mv "${FINGERPRINTS_FILE}.new" "${FINGERPRINTS_FILE}"
      fi
    else
      echo "Failed to extract package, using new fingerprints only"
      mv "${FINGERPRINTS_FILE}.new" "${FINGERPRINTS_FILE}"
    fi

    # Clean up
    rm -rf temp_fingerprints latest_fingerprints.tar.gz
  else
    echo "No previous fingerprints package found or unable to download, using new fingerprints only"
    mv "${FINGERPRINTS_FILE}.new" "${FINGERPRINTS_FILE}"
  fi

  create_package "${FINGERPRINTS_PACKAGE}" "${FINGERPRINTS_FILE}"
  upload_package "${FINGERPRINTS_PACKAGE}" "${FINGERPRINTS_PACKAGE_URL}"
}

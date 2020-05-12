#!/bin/bash

function retrieve_tests_metadata() {
  mkdir -p knapsack/ rspec_flaky/ rspec_profiling/

  if [[ ! -f "${KNAPSACK_RSPEC_SUITE_REPORT_PATH}" ]]; then
    wget -O "${KNAPSACK_RSPEC_SUITE_REPORT_PATH}" "http://${TESTS_METADATA_S3_BUCKET}.s3.amazonaws.com/${KNAPSACK_RSPEC_SUITE_REPORT_PATH}" || echo "{}" > "${KNAPSACK_RSPEC_SUITE_REPORT_PATH}"
  fi

  if [[ ! -f "${FLAKY_RSPEC_SUITE_REPORT_PATH}" ]]; then
    wget -O "${FLAKY_RSPEC_SUITE_REPORT_PATH}" "http://${TESTS_METADATA_S3_BUCKET}.s3.amazonaws.com/${FLAKY_RSPEC_SUITE_REPORT_PATH}" || echo "{}" > "${FLAKY_RSPEC_SUITE_REPORT_PATH}"
  fi
}

function update_tests_metadata() {
  echo "{}" > "${KNAPSACK_RSPEC_SUITE_REPORT_PATH}"

  scripts/merge-reports "${KNAPSACK_RSPEC_SUITE_REPORT_PATH}" knapsack/rspec*.json
  if [[ -n "${TESTS_METADATA_S3_BUCKET}" ]]; then
    if [[ "$CI_PIPELINE_SOURCE" == "schedule" ]]; then
      scripts/sync-reports put "${TESTS_METADATA_S3_BUCKET}" "${KNAPSACK_RSPEC_SUITE_REPORT_PATH}"
    else
      echo "Not uplaoding report to S3 as the pipeline is not a scheduled one."
    fi
  fi

  rm -f knapsack/rspec*.json

  scripts/merge-reports "${FLAKY_RSPEC_SUITE_REPORT_PATH}" rspec_flaky/all_*.json

  export FLAKY_RSPEC_GENERATE_REPORT="true"
  scripts/flaky_examples/prune-old-flaky-examples "${FLAKY_RSPEC_SUITE_REPORT_PATH}"

  if [[ -n ${TESTS_METADATA_S3_BUCKET} ]]; then
    if [[ "$CI_PIPELINE_SOURCE" == "schedule" ]]; then
      scripts/sync-reports put "${TESTS_METADATA_S3_BUCKET}" "${FLAKY_RSPEC_SUITE_REPORT_PATH}"
    else
      echo "Not uploading report to S3 as the pipeline is not a scheduled one."
    fi
  fi

  rm -f rspec_flaky/all_*.json rspec_flaky/new_*.json

  if [[ "$CI_PIPELINE_SOURCE" == "schedule" ]]; then
    scripts/insert-rspec-profiling-data
  else
    echo "Not inserting profiling data as the pipeline is not a scheduled one."
  fi
}

function rspec_simple_job() {
  local rspec_opts="${1}"

  export NO_KNAPSACK="1"

  scripts/gitaly-test-spawn

  bin/rspec --color --format documentation --format RspecJunitFormatter --out junit_rspec.xml ${rspec_opts}
}

function rspec_paralellized_job() {
  read -ra job_name <<< "${CI_JOB_NAME}"
  local test_tool="${job_name[0]}"
  local test_level="${job_name[1]}"
  local report_name=$(echo "${CI_JOB_NAME}" | sed -E 's|[/ ]|_|g') # e.g. 'rspec unit pg11 1/24' would become 'rspec_unit_pg11_1_24'
  local rspec_opts="${1}"
  local spec_folder_prefix=""

  if [[ "${test_tool}" =~ "-ee" ]]; then
    spec_folder_prefix="ee/"
  fi

  export KNAPSACK_LOG_LEVEL="debug"
  export KNAPSACK_REPORT_PATH="knapsack/${report_name}_report.json"

  # There's a bug where artifacts are sometimes not downloaded. Since specs can run without the Knapsack report, we can
  # handle the missing artifact gracefully here. See https://gitlab.com/gitlab-org/gitlab/-/issues/212349.
  if [[ ! -f "${KNAPSACK_RSPEC_SUITE_REPORT_PATH}" ]]; then
    echo "{}" > "${KNAPSACK_RSPEC_SUITE_REPORT_PATH}"
  fi

  cp "${KNAPSACK_RSPEC_SUITE_REPORT_PATH}" "${KNAPSACK_REPORT_PATH}"

  if [[ -z "${KNAPSACK_TEST_FILE_PATTERN}" ]]; then
    pattern=$(ruby -r./lib/quality/test_level.rb -e "puts Quality::TestLevel.new(%(${spec_folder_prefix})).pattern(:${test_level})")
    export KNAPSACK_TEST_FILE_PATTERN="${pattern}"
  fi

  echo "KNAPSACK_TEST_FILE_PATTERN: ${KNAPSACK_TEST_FILE_PATTERN}"

  if [[ -d "ee/" ]]; then
    export KNAPSACK_GENERATE_REPORT="true"
    export FLAKY_RSPEC_GENERATE_REPORT="true"
    export SUITE_FLAKY_RSPEC_REPORT_PATH="${FLAKY_RSPEC_SUITE_REPORT_PATH}"
    export FLAKY_RSPEC_REPORT_PATH="rspec_flaky/all_${report_name}_report.json"
    export NEW_FLAKY_RSPEC_REPORT_PATH="rspec_flaky/new_${report_name}_report.json"

    if [[ ! -f $FLAKY_RSPEC_REPORT_PATH ]]; then
      echo "{}" > "${FLAKY_RSPEC_REPORT_PATH}"
    fi

    if [[ ! -f $NEW_FLAKY_RSPEC_REPORT_PATH ]]; then
      echo "{}" > "${NEW_FLAKY_RSPEC_REPORT_PATH}"
    fi
  fi

  scripts/gitaly-test-spawn

  mkdir -p tmp/memory_test

  export MEMORY_TEST_PATH="tmp/memory_test/${report_name}_memory.csv"

  knapsack rspec "-Ispec --color --format documentation --format RspecJunitFormatter --out junit_rspec.xml ${rspec_opts}"

  date
}

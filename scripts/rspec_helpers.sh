#!/usr/bin/env bash

function update_tests_metadata() {
  scripts/setup/tests-metadata.rb update

  if [[ "$CI_PIPELINE_SOURCE" == "schedule" ]]; then
    if [[ -n "$RSPEC_PROFILING_PGSSLKEY" ]]; then
      chmod 0600 $RSPEC_PROFILING_PGSSLKEY
    fi
    PGSSLMODE=$RSPEC_PROFILING_PGSSLMODE PGSSLROOTCERT=$RSPEC_PROFILING_PGSSLROOTCERT PGSSLCERT=$RSPEC_PROFILING_PGSSLCERT PGSSLKEY=$RSPEC_PROFILING_PGSSLKEY scripts/insert-rspec-profiling-data
  else
    echo "Not inserting profiling data as the pipeline is not a scheduled one."
  fi

  cleanup_individual_job_reports
}

function retrieve_tests_mapping() {
  mkdir -p $(dirname "$RSPEC_PACKED_TESTS_MAPPING_PATH")

  if [[ ! -f "${RSPEC_PACKED_TESTS_MAPPING_PATH}" ]]; then
    (curl --fail --location  -o "${RSPEC_PACKED_TESTS_MAPPING_PATH}.gz" "https://gitlab-org.gitlab.io/gitlab/${RSPEC_PACKED_TESTS_MAPPING_PATH}.gz" && gzip -d "${RSPEC_PACKED_TESTS_MAPPING_PATH}.gz") || echo "{}" > "${RSPEC_PACKED_TESTS_MAPPING_PATH}"
  fi

  scripts/unpack-test-mapping "${RSPEC_PACKED_TESTS_MAPPING_PATH}" "${RSPEC_TESTS_MAPPING_PATH}"
}

function retrieve_frontend_fixtures_mapping() {
  mkdir -p $(dirname "$FRONTEND_FIXTURES_MAPPING_PATH")

  if [[ ! -f "${FRONTEND_FIXTURES_MAPPING_PATH}" ]]; then
    (curl --fail --location  -o "${FRONTEND_FIXTURES_MAPPING_PATH}" "https://gitlab-org.gitlab.io/gitlab/${FRONTEND_FIXTURES_MAPPING_PATH}") || echo "{}" > "${FRONTEND_FIXTURES_MAPPING_PATH}"
  fi
}

function update_tests_mapping() {
  pack_and_gzip_mapping "${RSPEC_TESTS_MAPPING_PATH}" "${RSPEC_PACKED_TESTS_MAPPING_PATH}" crystalball/described/rspec*.yml

  pack_and_gzip_mapping "${RSPEC_TESTS_MAPPING_ALT_PATH}" "${RSPEC_PACKED_TESTS_MAPPING_ALT_PATH}" crystalball/coverage/rspec*.yml
}

function pack_and_gzip_mapping() {
  local mapping_path="${1}"
  local packed_path="${2}"
  local crystal_yaml_files=("${@:3}")

  if test -z "${crystal_yaml_files[1]}"; then
    echo "No crystalball rspec data for ${mapping_path}"
    return 0
  fi

  scripts/generate-test-mapping "${mapping_path}" "${crystal_yaml_files[@]}"
  scripts/pack-test-mapping "${mapping_path}" "${packed_path}"
  gzip "${packed_path}"
  rm -f "${packed_path}" "${mapping_path}" "${crystal_yaml_files[@]}"
}

function retrieve_failed_tests() {
  local directory_for_output_reports="${1}"
  local failed_tests_format="${2}"
  local pipeline_index="${3}"
  local pipeline_report_path="tmp/test_results/${pipeline_index}/test_reports.json"

  echo 'Attempting to build pipeline test report...'

  scripts/pipeline_test_report_builder.rb --output-file-path "${pipeline_report_path}" --pipeline-index "${pipeline_index}"

  echo 'Generating failed tests lists...'

  scripts/failed_tests.rb --previous-tests-report-path "${pipeline_report_path}" --format "${failed_tests_format}" --output-directory "${directory_for_output_reports}"
}

function rspec_args() {
  local rspec_opts="${1}"
  local json_report_file="${2:-rspec/rspec-${CI_JOB_ID}.json}"
  local junit_report_file="${3:-rspec/rspec-${CI_JOB_ID}.xml}"

  echo "-Ispec -rspec_helper --color --failure-exit-code 1 --error-exit-code 2 --format documentation --format Support::Formatters::JsonFormatter --out ${json_report_file} --format RspecJunitFormatter --out ${junit_report_file} ${rspec_opts}"
}

function rspec_simple_job() {
  export NO_KNAPSACK="1"

  local rspec_cmd="bin/rspec $(rspec_args "${1}" "${2}" "${3}")"
  echoinfo "Running RSpec command: ${rspec_cmd}"

  eval "${rspec_cmd}"
}

function rspec_simple_job_with_retry () {
  local rspec_run_status=0

  rspec_simple_job "${1}" "${2}" "${3}" || rspec_run_status=$?

  handle_retry_rspec_in_new_process $rspec_run_status
}

# Below is the list of options (https://linuxcommand.org/lc3_man_pages/seth.html)
#
#   allexport    same as -a
#   braceexpand  same as -B
#   emacs        use an emacs-style line editing interface
#   errexit      same as -e
#   errtrace     same as -E
#   functrace    same as -T
#   hashall      same as -h
#   histexpand   same as -H
#   history      enable command history
#   ignoreeof    the shell will not exit upon reading EOF
#   interactive-comments
#                 allow comments to appear in interactive commands
#   keyword      same as -k
#   monitor      same as -m
#   noclobber    same as -C
#   noexec       same as -n
#   noglob       same as -f
#   nolog        currently accepted but ignored
#   notify       same as -b
#   nounset      same as -u
#   onecmd       same as -t
#   physical     same as -P
#   pipefail     the return value of a pipeline is the status of
#                 the last command to exit with a non-zero status,
#                 or zero if no command exited with a non-zero status
#   posix        change the behavior of bash where the default
#                 operation differs from the Posix standard to
#                 match the standard
#   privileged   same as -p
#   verbose      same as -v
#   vi           use a vi-style line editing interface
#   xtrace       same as -x
function debug_shell_options() {
  echoinfo "Shell set options (set -o) enabled:"
  echoinfo "$(set -o | grep 'on$')"
}

function debug_rspec_variables() {
  echoinfo "RETRY_FAILED_TESTS_IN_NEW_PROCESS: ${RETRY_FAILED_TESTS_IN_NEW_PROCESS:-}"

  echoinfo "KNAPSACK_GENERATE_REPORT: ${KNAPSACK_GENERATE_REPORT:-}"
  echoinfo "FLAKY_RSPEC_GENERATE_REPORT: ${FLAKY_RSPEC_GENERATE_REPORT:-}"

  echoinfo "KNAPSACK_TEST_FILE_PATTERN: ${KNAPSACK_TEST_FILE_PATTERN:-}"
  echoinfo "KNAPSACK_LOG_LEVEL: ${KNAPSACK_LOG_LEVEL:-}"
  echoinfo "KNAPSACK_REPORT_PATH: ${KNAPSACK_REPORT_PATH:-}"

  echoinfo "FLAKY_RSPEC_SUITE_REPORT_PATH: ${FLAKY_RSPEC_SUITE_REPORT_PATH:-}"
  echoinfo "FLAKY_RSPEC_REPORT_PATH: ${FLAKY_RSPEC_REPORT_PATH:-}"
  echoinfo "NEW_FLAKY_RSPEC_REPORT_PATH: ${NEW_FLAKY_RSPEC_REPORT_PATH:-}"
  echoinfo "RSPEC_SKIPPED_TESTS_REPORT_PATH: ${RSPEC_SKIPPED_TESTS_REPORT_PATH:-}"

  echoinfo "CRYSTALBALL: ${CRYSTALBALL:-}"

  echoinfo "RSPEC_TESTS_MAPPING_ENABLED: ${RSPEC_TESTS_MAPPING_ENABLED:-}"
  echoinfo "RSPEC_TESTS_FILTER_FILE: ${RSPEC_TESTS_FILTER_FILE:-}"
}

function handle_retry_rspec_in_new_process() {
  local rspec_run_status="${1}"
  local new_exit_code="${1}"
  local rspec_retry_status=0

  if [[ $rspec_run_status -eq 3 ]]; then
    echoerr "Not retrying failing examples since we failed early on purpose!"
    change_exit_code_if_applicable $rspec_run_status || new_exit_code=$?
    exit "${new_exit_code}"
  fi

  if [[ $rspec_run_status -eq 2 ]]; then
    echoerr "Not retrying failing examples since there were errors happening outside of the RSpec examples!"
    change_exit_code_if_applicable $rspec_run_status || new_exit_code=$?
    exit "${new_exit_code}"
  fi

  if [[ $rspec_run_status -ne 0 ]]; then
    if is_rspec_last_run_results_file_missing; then
      change_exit_code_if_applicable $rspec_run_status || new_exit_code=$?
      exit "${new_exit_code}"
    fi

    local failed_examples_count=$(grep -c " failed" "${RSPEC_LAST_RUN_RESULTS_FILE}")
    if [[ "${failed_examples_count}" -eq "${RSPEC_FAIL_FAST_THRESHOLD}" ]]; then
      echoerr "Not retrying failing examples since we reached the maximum number of allowed test failures!"
      change_exit_code_if_applicable $rspec_run_status || new_exit_code=$?
      exit "${new_exit_code}"
    fi

    retry_failed_rspec_examples $rspec_run_status || rspec_retry_status=$?
  else
    echosuccess "No examples to retry, congrats!"
    exit "${rspec_run_status}"
  fi

  # The retry in a new RSpec process succeeded.
  if [[ $rspec_retry_status -eq 0 ]]; then
    exit "${rspec_retry_status}"
  fi

  # At this stage, we know the CI/CD job will fail.
  #
  # We'll change the exit code of the CI job.
  change_exit_code_if_applicable $rspec_retry_status || new_exit_code=$?
  exit $new_exit_code
}

function change_exit_code_if_applicable() {
  local previous_exit_status=$1
  local found_known_flaky_test=$previous_exit_status
  local found_infra_error=$previous_exit_status
  local new_exit_code=$previous_exit_status

  # We need to call the GitLab API for those functions.
  if [[ -n "$TEST_FAILURES_PROJECT_TOKEN" ]]; then
    change_exit_code_if_known_flaky_tests $previous_exit_status || found_known_flaky_test=$?
    change_exit_code_if_known_infra_error $previous_exit_status || found_infra_error=$?
  else
    echoinfo "TEST_FAILURES_PROJECT_TOKEN is not set. We won't try to change the exit code."
  fi

  # Update new_exit_code if either of the checks changed the values
  # Ensure infra error exit code takes precedence because we want to retry it if possible
  echo
  echo "found_known_flaky_test: $found_known_flaky_test"
  echo "found_infra_error: $found_infra_error"

  if [[ $found_infra_error -ne $previous_exit_status ]]; then
    new_exit_code=$found_infra_error
    alert_job_in_slack $new_exit_code "Known infra error caused this job to fail"
  elif [[ $found_known_flaky_test -ne $previous_exit_status ]]; then
    new_exit_code=$found_known_flaky_test
  fi

  echo "New exit code: $new_exit_code"
  return $new_exit_code
}

function change_exit_code_if_known_flaky_tests() {
  new_exit_code=$1
  echo
  echo "*******************************************************"
  echo "Checking whether known flaky tests failed the job"
  echo "*******************************************************"

  found_known_flaky_tests_status=0
  found_known_flaky_tests_output=$(found_known_flaky_tests) || found_known_flaky_tests_status=$?

  echo "${found_known_flaky_tests_output}"
  if [[ $found_known_flaky_tests_status -eq 0 ]]; then
    echo
    echo "Changing the CI/CD job exit code to 112."

    new_exit_code=112
  else
    echo
    echo "Not changing the CI/CD job exit code."
  fi

  return "${new_exit_code}"
}

function change_exit_code_if_known_infra_error() {
  exit_code=$1

  if [[ "${DETECT_INFRA_ERRORS}" != "true" ]]; then
    echoinfo "Auto-retrying infrastructure errors is disabled. Exiting with exit code ${exit_code}".
  elif [[ $exit_code -ne 0 ]]; then
    echo
    echo "*******************************************************"
    echo "Checking whether known infra error failed the job"
    echo "*******************************************************"

    found_infrastructure_error_status=0
    found_known_flaky_tests_output=$(found_infrastructure_error) || found_infrastructure_error_status=$?

    if [[ $found_infrastructure_error_status -eq 0 ]]; then
      echo
      echo "Changing the CI/CD job exit code to 110."

      exit_code=110
    else
      echo
      echo "Not changing the CI/CD job exit code."
    fi
  fi

  return $exit_code
}

function found_known_flaky_tests() {
  # For the input files, we want to get both rspec-${CI_JOB_ID}.json (first RSpec run)
  # and rspec-retry-${CI_JOB_ID}.json (second RSpec run).
  #
  # Depending on where this function will be called,
  # we might have the two files, just one, or none available.
  bundle exec existing-test-health-issue \
    --token "${TEST_FAILURES_PROJECT_TOKEN}" \
    --project "gitlab-org/gitlab" \
    --input-files "rspec/rspec-*${CI_JOB_ID}.json" \
    --health-problem-type failures;
}

function found_infrastructure_error() {
  bundle exec detect-infrastructure-failures \
    --job-id "${CI_JOB_ID}" \
    --project "${CI_PROJECT_ID}" \
    --token "${TEST_FAILURES_PROJECT_TOKEN}"
}

function rspec_parallelized_job() {
  echo "[$(date '+%H:%M:%S')] Starting rspec_parallelized_job"

  read -ra job_name <<< "${CI_JOB_NAME}"
  local test_tool="${job_name[0]}"
  local test_level="${job_name[1]}"
  # e.g. 'rspec unit pg14 1/24 278964' would become 'rspec_unit_pg14_1_24_278964'
  local report_name=$(echo "${CI_JOB_NAME} ${CI_PROJECT_ID}" | sed -E 's|[/ ]|_|g')
  local rspec_opts="${1:-}"
  local rspec_tests_mapping_enabled="${RSPEC_TESTS_MAPPING_ENABLED:-}"
  local spec_folder_prefixes=""
  local rspec_flaky_folder_path="$(dirname "${FLAKY_RSPEC_SUITE_REPORT_PATH}")/"
  local knapsack_folder_path="$(dirname "${KNAPSACK_RSPEC_SUITE_REPORT_PATH}")/"
  local rspec_run_status=0

  if [[ "${test_tool}" =~ "-ee" ]]; then
    spec_folder_prefixes="'ee/'"
  fi

  if [[ "${test_tool}" =~ "-jh" ]]; then
    spec_folder_prefixes="'jh/'"
  fi

  if [[ "${test_tool}" =~ "-all" ]]; then
    spec_folder_prefixes="['', 'ee/', 'jh/']"
  fi

  export KNAPSACK_LOG_LEVEL="debug"
  export KNAPSACK_REPORT_PATH="${knapsack_folder_path}${report_name}_report.json"

  # There's a bug where artifacts are sometimes not downloaded. Since specs can run without the Knapsack report, we can
  # handle the missing artifact gracefully here. See https://gitlab.com/gitlab-org/gitlab/-/issues/212349.
  if [[ ! -f "${KNAPSACK_RSPEC_SUITE_REPORT_PATH}" ]]; then
    echo "{}" > "${KNAPSACK_RSPEC_SUITE_REPORT_PATH}"
  fi

  cp "${KNAPSACK_RSPEC_SUITE_REPORT_PATH}" "${KNAPSACK_REPORT_PATH}"

  export KNAPSACK_TEST_FILE_PATTERN=$(ruby -r./tooling/quality/test_level.rb -e "puts Quality::TestLevel.new(${spec_folder_prefixes}).pattern(:${test_level})")
  export FLAKY_RSPEC_REPORT_PATH="${rspec_flaky_folder_path}all_${report_name}_report.json"
  export NEW_FLAKY_RSPEC_REPORT_PATH="${rspec_flaky_folder_path}new_${report_name}_report.json"
  export KNAPSACK_GENERATE_REPORT="true"
  export FLAKY_RSPEC_GENERATE_REPORT="true"

  if [[ ! -f $FLAKY_RSPEC_REPORT_PATH ]]; then
    echo "{}" > "${FLAKY_RSPEC_REPORT_PATH}"
  fi

  if [[ ! -f $NEW_FLAKY_RSPEC_REPORT_PATH ]]; then
    echo "{}" > "${NEW_FLAKY_RSPEC_REPORT_PATH}"
  fi

  debug_rspec_variables
  debug_shell_options

  if [[ -n "${rspec_tests_mapping_enabled}" ]]; then
    tooling/bin/parallel_rspec --rspec_args "$(rspec_args "${rspec_opts}")" --filter "${RSPEC_TESTS_FILTER_FILE}" || rspec_run_status=$?
  else
    tooling/bin/parallel_rspec --rspec_args "$(rspec_args "${rspec_opts}")" || rspec_run_status=$?
  fi

  echoinfo "RSpec exited with ${rspec_run_status}."

  handle_retry_rspec_in_new_process $rspec_run_status
}

# this function must be executed from 'qa' directory
function run_e2e_specs() {
  local url=$1
  local tests=$2
  local tags=$3

  export QA_COMMAND="bundle exec bin/qa ${QA_SCENARIO:=Test::Instance::All} $url -- $tests $tags --order random --force-color --format documentation"
  echo "Running e2e specs via command: '$QA_COMMAND'"

  if eval "$QA_COMMAND"; then
    echo "Test run finished successfully"
  else
    retry_failed_e2e_rspec_examples
  fi
}

# this function must be executed from 'qa' directory
function retry_failed_e2e_rspec_examples() {
  local rspec_run_status=0

  if [[ "${QA_COMMAND}" == "" ]]; then
    echoerr "Missing variable 'QA_COMMAND' needed to trigger tests"
    exit 1
  fi

  if is_rspec_last_run_results_file_missing; then
    exit 1
  fi

  if last_run_has_no_failures; then
    exit 1
  fi

  export QA_RSPEC_RETRIED="true"
  export NO_KNAPSACK="true"

  echoinfo "Initial test run failed, retrying tests in new process" "yes"

  if eval "$QA_COMMAND --only-failures"; then
    echosuccess "Retry run finished successfully" "yes"
  else
    rspec_run_status=$?
    echoerr "Retry run did not finish successfully, job will be failed!" "yes"
  fi

  # default junit file pattern is set in 'qa/qa/specs/runner.rb'
  local junit_retry_file=$(ls tmp/rspec-*-retried-true.xml)

  echoinfo "Merging junit reports" "yes"
  if [[ ! -f "${junit_retry_file}" ]]; then
    echoerr "Junit retry file not found '${junit_retry_file}', skipping report merge"
    return 0
  fi

  if [[ "$QA_RUN_IN_PARALLEL" == "true" ]]; then
    echoinfo "Parallel run detected, merging with parallel reports"
    bundle exec junit_merge tmp/rspec-*-retried-false*.xml
    mv "$(ls tmp/rspec-*-retried-false*.xml | tail -n 1)" "tmp/rspec-${CI_JOB_ID}.xml"
    rm tmp/rspec-*-retried-false*.xml

    bundle exec junit_merge --update-only $junit_retry_file "tmp/rspec-${CI_JOB_ID}.xml"
  else
    bundle exec junit_merge --update-only $junit_retry_file tmp/rspec-*-retried-false.xml
  fi
  rm $junit_retry_file
  echosuccess " junit results merged successfully!"

  exit $rspec_run_status
}

function retry_failed_rspec_examples() {
  local previous_exit_status=$1
  local rspec_run_status=0

  if [[ "${RETRY_FAILED_TESTS_IN_NEW_PROCESS}" != "true" ]]; then
    echoerr "Not retrying failing examples since \$RETRY_FAILED_TESTS_IN_NEW_PROCESS != 'true'!"
    exit $previous_exit_status
  fi

  if is_rspec_last_run_results_file_missing; then
    exit $previous_exit_status
  fi

  # Job metrics for influxDB/Grafana
  tooling/bin/update_job_metrics_tag rspec_retried_in_new_process "true" || true

  # Keep track of the tests that are retried, later consolidated in a single file by the `rspec:flaky-tests-report` job
  local failed_examples=$(grep " failed" ${RSPEC_LAST_RUN_RESULTS_FILE})
  echoinfo "RSPEC_RETRIED_TESTS_REPORT_PATH: ${RSPEC_RETRIED_TESTS_REPORT_PATH:-}"

  echo "${CI_JOB_URL}" > "${RSPEC_RETRIED_TESTS_REPORT_PATH:-}"
  echo $failed_examples >> "${RSPEC_RETRIED_TESTS_REPORT_PATH:-}"

  echoinfo "Retrying the failing examples in a new RSpec process..."

  install_junit_merge_gem

  # Disable Crystalball on retry to not overwrite the existing report
  export CRYSTALBALL="false"

  # Disable simplecov so retried tests don't override test coverage report
  export SIMPLECOV=0

  local default_knapsack_pattern="{,ee/,jh/}spec/{,**/}*_spec.rb"
  local knapsack_test_file_pattern="${KNAPSACK_TEST_FILE_PATTERN:-$default_knapsack_pattern}"
  local json_retry_file="rspec/rspec-retry-${CI_JOB_ID}.json"
  local junit_retry_file="rspec/rspec-retry-${CI_JOB_ID}.xml"

  # Retry only the tests that failed on first try
  rspec_simple_job "--only-failures --pattern \"${knapsack_test_file_pattern}\"" "${json_retry_file}" "${junit_retry_file}" || rspec_run_status=$?

  # Merge the reports from retry into the first-try report
  scripts/merge-reports "rspec/rspec-${CI_JOB_ID}.json" "${json_retry_file}"
  junit_merge "${junit_retry_file}" "rspec/rspec-${CI_JOB_ID}.xml" --update-only

  # The tests are flaky because they succeeded after being retried.
  if [[ $rspec_run_status -eq 0 ]]; then
    # Make the pipeline "pass with warnings" if the flaky tests are part of this MR.
    warn_on_successfully_retried_test
  fi

  return $rspec_run_status
}

# Exit with an allowed_failure exit code if the flaky test was part of the MR that triggered this pipeline
function warn_on_successfully_retried_test {
  local changed_files=$(git diff --name-only $CI_MERGE_REQUEST_TARGET_BRANCH_SHA | grep spec)
  echoinfo "A test was flaky and succeeded after being retried. Checking to see if flaky test is part of this MR..."

  if [[ "$changed_files" == "" ]]; then
    echoinfo "Flaky test was not part of this MR."
    return
  fi

  while read changed_file
  do
    # include the root path in the regexp to eliminate false positives
    changed_file="^\./$changed_file"

    if grep -q "${changed_file}" "${RSPEC_RETRIED_TESTS_REPORT_PATH}"; then
      echoinfo "Flaky test '$changed_file' was found in the list of files changed by this MR."
      echoinfo "Exiting with code $SUCCESSFULLY_RETRIED_TEST_EXIT_CODE."
      exit $SUCCESSFULLY_RETRIED_TEST_EXIT_CODE
    fi
  done <<< "$changed_files"

  echoinfo "Flaky test was not part of this MR."
}

function rspec_rerun_previous_failed_tests() {
  local test_file_count_threshold=${RSPEC_PREVIOUS_FAILED_TEST_FILE_COUNT_THRESHOLD:-10}
  local matching_tests_file=${1}
  local rspec_opts=${2}
  local test_files="$(select_existing_files < "${matching_tests_file}")"
  local test_file_count=$(wc -w "${matching_tests_file}" | awk {'print $1'})

  if [[ "${test_file_count}" -gt "${test_file_count_threshold}" ]]; then
    echo "This job is intentionally exited because there are more than ${test_file_count_threshold} test files to rerun."
    exit 0
  fi

  if [[ -n $test_files ]]; then
    rspec_simple_job_with_retry "${test_files}"
  else
    echo "No failed test files to rerun"
  fi
}

function rspec_fail_fast() {
  local test_file_count_threshold=${RSPEC_FAIL_FAST_TEST_FILE_COUNT_THRESHOLD:-10}
  local matching_tests_file=${1}
  local rspec_opts=${2}
  local test_files="$(cat "${matching_tests_file}")"
  local test_file_count=$(wc -w "${matching_tests_file}" | awk {'print $1'})

  if [[ "${test_file_count}" -gt "${test_file_count_threshold}" ]]; then
    echo "This job is intentionally skipped because there are more than ${test_file_count_threshold} test files matched,"
    echo "which would take too long to run in this job."
    echo "All the tests would be run in other rspec jobs."
    exit 0
  fi

  if [[ -n $test_files ]]; then
    rspec_simple_job_with_retry "${rspec_opts} ${test_files}"
  else
    echo "No rspec fail-fast tests to run"
  fi
}

function filter_rspec_matched_foss_tests() {
  local matching_tests_file="${1}"
  local foss_matching_tests_file="${2}"

  # Keep only FOSS files that exists
  cat ${matching_tests_file} | ruby -e 'puts $stdin.read.split(" ").select { |f| f.start_with?("spec/") && File.exist?(f) }.join(" ")' > "${foss_matching_tests_file}"
}

function filter_rspec_matched_ee_tests() {
  local matching_tests_file="${1}"
  local ee_matching_tests_file="${2}"

  # Keep only EE files that exists
  cat ${matching_tests_file} | ruby -e 'puts $stdin.read.split(" ").select { |f| f.start_with?("ee/spec/") && File.exist?(f) }.join(" ")' > "${ee_matching_tests_file}"
}

function generate_frontend_fixtures_mapping() {
  local pattern=""

  if [[ -d "ee/" ]]; then
    pattern=",ee/"
  fi

  if [[ -d "jh/" ]]; then
    pattern="${pattern},jh/"
  fi

  if [[ -n "${pattern}" ]]; then
    pattern="{${pattern}}"
  fi

  pattern="${pattern}spec/frontend/fixtures/**/*.rb"

  export GENERATE_FRONTEND_FIXTURES_MAPPING="true"

  mkdir -p $(dirname "$FRONTEND_FIXTURES_MAPPING_PATH")

  rspec_simple_job_with_retry "--pattern \"${pattern}\""
}

function cleanup_individual_job_reports() {
  local rspec_flaky_folder_path="$(dirname "${FLAKY_RSPEC_SUITE_REPORT_PATH}")/"
  local knapsack_folder_path="$(dirname "${KNAPSACK_RSPEC_SUITE_REPORT_PATH}")/"

  rm -rf ${knapsack_folder_path:-unknown_folder}rspec*.json \
    ${rspec_flaky_folder_path:-unknown_folder}all_*.json \
    ${rspec_flaky_folder_path:-unknown_folder}new_*.json \
    rspec/skipped_flaky_tests_*_report.txt \
    rspec/retried_tests_*_report.txt \
    ${RSPEC_LAST_RUN_RESULTS_FILE:-unknown_folder} \
    ${RSPEC_PROFILING_FOLDER_PATH:-unknown_folder}/**/*
  rmdir ${RSPEC_PROFILING_FOLDER_PATH:-unknown_folder} || true
}

function generate_flaky_tests_reports() {
  debug_rspec_variables

  mkdir -p rspec/

  find rspec/ -type f -name 'skipped_tests-*.txt' -exec cat {} + >> "rspec/skipped_tests_report.txt"
  find rspec/ -type f -name 'retried_tests-*.txt' -exec cat {} + >> "rspec/retried_tests_report.txt"

  cleanup_individual_job_reports
}

function is_rspec_last_run_results_file_missing() {
  # Sometimes the file isn't created or is empty.
  if [[ ! -f "${RSPEC_LAST_RUN_RESULTS_FILE}" ]] || [[ ! -s "${RSPEC_LAST_RUN_RESULTS_FILE}" ]]; then
    echoerr "The file set inside RSPEC_LAST_RUN_RESULTS_FILE ENV variable does not exist or is empty. As a result, we won't retry failed specs."
    return 0
  else
    return 1
  fi
}

# when rspec process fails outside of examples, it can create last run results that has no failures to retry
# this will lead in passed retry run due to not running any examples
function last_run_has_no_failures() {
  failed_examples=$(grep -o "failed" ${RSPEC_LAST_RUN_RESULTS_FILE} | wc -l)
  if [ $failed_examples -lt 1 ]; then
    echoerr "The file set inside RSPEC_LAST_RUN_RESULTS_FILE ENV variable does not have any specs with status 'failed'. As a result, we won't retry failed specs."
    return 0
  else
    return 1
  fi
}

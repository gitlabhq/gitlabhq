# frozen_string_literal: true

namespace :ci do
  require_relative "helpers/util"

  include Task::Helpers::Util

  desc "Detect changes and populate test variables for selective test execution and feature flag testing"
  task :detect_changes, [:env_file] do |_, args|
    env_file = args[:env_file]
    abort("ERROR: Path for environment file must be provided") unless env_file

    diff = mr_diff
    labels = mr_labels
    # Assign mapping of groups to tests in stages other than the groups defined stage
    additional_group_spec_list = { 'gitaly' => %w[create] }

    qa_changes = QA::Tools::Ci::QaChanges.new(diff, labels, additional_group_spec_list)
    logger = qa_changes.logger

    logger.info("Analyzing merge request changes")
    # skip running tests when only quarantine changes detected
    if qa_changes.quarantine_changes?
      logger.info(" merge request contains only quarantine changes, e2e test execution will be skipped!")
      append_to_file(env_file, "QA_SKIP_ALL_TESTS=true")
      next
    end

    run_all_label_present = mr_labels.include?("pipeline:run-all-e2e")
    # on run-all label of framework changes do not infer specific tests
    tests = run_all_label_present || qa_changes.framework_changes? ? nil : qa_changes.qa_tests

    # When QA_TESTS only contain folders and no specific specs, populate KNAPSACK_TEST_FILE_PATTERN
    if tests && tests.split(' ').none? { |item| item.include?('_spec') }
      test_paths = tests.split(' ').map { |item| "#{item}**/*" }

      files_pattern = "{#{test_paths.join(',')}}"

      logger.info(" Files pattern for tests: #{files_pattern}")
      append_to_file(env_file, <<~TXT)
        KNAPSACK_TEST_FILE_PATTERN='#{files_pattern}'
      TXT
    end

    if run_all_label_present
      logger.info(" merge request has pipeline:run-all-e2e label, full test suite will be executed")
      append_to_file(env_file, "QA_RUN_ALL_E2E_LABEL=true\n")
    elsif qa_changes.framework_changes? # run all tests when framework changes detected
      logger.info(" merge request contains qa framework changes, full test suite will be executed")
      append_to_file(env_file, "QA_FRAMEWORK_CHANGES=true\n")
    elsif tests
      logger.info(" detected following specs to execute: '#{tests}'")
    else
      logger.info(" no specific specs to execute detected")
    end

    # always check all test suites in case a suite is defined but doesn't have any runnable specs
    suites = QA::Tools::Ci::NonEmptySuites.new(tests).fetch
    append_to_file(env_file, <<~TXT)
      QA_SUITES='#{suites}'
      QA_TESTS='#{tests}'
    TXT

    # check if mr contains feature flag changes
    feature_flags = QA::Tools::Ci::FfChanges.new(diff).fetch
    append_to_file(env_file, "QA_FEATURE_FLAGS='#{feature_flags}'")
  end

  desc "Export test run metrics to influxdb"
  task :export_test_metrics, [:glob] do |_, args|
    raise("Metrics file glob pattern is required") unless args[:glob]

    QA::Tools::Ci::TestMetrics.export(args[:glob])
  end
end

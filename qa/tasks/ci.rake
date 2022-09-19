# frozen_string_literal: true

require_relative "helpers/util"

# rubocop:disable Rails/RakeEnvironment
namespace :ci do
  include Task::Helpers::Util

  desc "Detect changes and populate test variables for selective test execution and feature flag testing"
  task :detect_changes, [:env_file] do |_, args|
    env_file = args[:env_file]
    abort("ERROR: Path for environment file must be provided") unless env_file

    diff = mr_diff
    labels = mr_labels

    qa_changes = QA::Tools::Ci::QaChanges.new(diff, labels)
    logger = qa_changes.logger

    logger.info("Analyzing merge request changes")
    # skip running tests when only quarantine changes detected
    if qa_changes.quarantine_changes?
      logger.info(" merge request contains only quarantine changes, e2e test execution will be skipped!")
      append_to_file(env_file, <<~TXT)
        QA_SKIP_ALL_TESTS=true
      TXT
      next
    end

    tests = qa_changes.qa_tests
    if qa_changes.framework_changes? # run all tests when framework changes detected
      logger.info(" merge request contains qa framework changes, full test suite will be executed")
      append_to_file(env_file, <<~TXT)
        QA_FRAMEWORK_CHANGES=true
      TXT
    elsif tests
      logger.info(" detected following specs to execute: '#{tests}'")
    else
      logger.info(" no specific specs to execute detected")
    end

    # always check all test suites in case a suite is defined but doesn't have any runnable specs
    suites = QA::Tools::Ci::NonEmptySuites.new(tests).fetch
    append_to_file(env_file, <<~TXT)
      QA_TESTS='#{tests}'
      QA_SUITES='#{suites}'
    TXT

    # check if mr contains feature flag changes
    feature_flags = QA::Tools::Ci::FfChanges.new(diff).fetch
    append_to_file(env_file, <<~TXT)
      QA_FEATURE_FLAGS='#{feature_flags}'
    TXT
  end

  desc "Download test results from downstream pipeline"
  task :download_test_results, [:trigger_name, :test_report_job_name, :report_path] do |_, args|
    QA::Tools::Ci::TestResults.get(args[:trigger_name], args[:test_report_job_name], args[:report_path])
  end
end
# rubocop:enable Rails/RakeEnvironment

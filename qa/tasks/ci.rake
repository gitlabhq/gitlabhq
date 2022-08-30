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

    # run all tests when framework changes detected
    if qa_changes.framework_changes?
      logger.info(" merge request contains qa framework changes, full test suite will be executed")
      append_to_file(env_file, <<~TXT)
        QA_FRAMEWORK_CHANGES=true
      TXT
    end

    # detect if any of the test suites would not execute any tests and populate environment variables
    tests = qa_changes.qa_tests
    if tests
      logger.info(" following changed specs detected: '#{tests}'")
    else
      logger.info(" no specific spec changes detected")
    end

    # always check all test suites in case a suite is defined but doesn't have any runnable specs
    suites = QA::Tools::Ci::NonEmptySuites.new(tests).fetch
    append_to_file(env_file, <<~TXT)
      QA_TESTS=#{tests}
      QA_SUITES=#{suites}
    TXT

    # check if mr contains feature flag changes
    feature_flags = QA::Tools::Ci::FfChanges.new(diff).fetch
    append_to_file(env_file, <<~TXT)
      QA_FEATURE_FLAGS=#{feature_flags}
    TXT
  end
end
# rubocop:enable Rails/RakeEnvironment

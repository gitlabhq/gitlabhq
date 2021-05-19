# frozen_string_literal: true

module Gitlab
  module Ci
    module Reports
      class TestFailureHistory
        include Gitlab::Utils::StrongMemoize

        def initialize(failed_junit_tests, project)
          @failed_junit_tests = build_map(failed_junit_tests)
          @project = project
        end

        def load!
          recent_failures_count.each do |key_hash, count|
            failed_junit_tests[key_hash].set_recent_failures(count, project.default_branch_or_main)
          end
        end

        private

        attr_reader :report, :project, :failed_junit_tests

        def recent_failures_count
          ::Ci::UnitTestFailure.recent_failures_count(
            project: project,
            unit_test_keys: failed_junit_tests.keys
          )
        end

        def build_map(junit_tests)
          {}.tap do |hash|
            junit_tests.each do |test|
              hash[test.key] = test
            end
          end
        end
      end
    end
  end
end

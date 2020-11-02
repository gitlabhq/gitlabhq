# frozen_string_literal: true

module Gitlab
  module Ci
    module Reports
      class TestFailureHistory
        include Gitlab::Utils::StrongMemoize

        def initialize(failed_test_cases, project)
          @failed_test_cases = build_map(failed_test_cases)
          @project = project
        end

        def load!
          return unless Feature.enabled?(:test_failure_history, project)

          recent_failures_count.each do |key_hash, count|
            failed_test_cases[key_hash].set_recent_failures(count, project.default_branch_or_master)
          end
        end

        private

        attr_reader :report, :project, :failed_test_cases

        def recent_failures_count
          ::Ci::TestCaseFailure.recent_failures_count(
            project: project,
            test_case_keys: failed_test_cases.keys
          )
        end

        def build_map(test_cases)
          {}.tap do |hash|
            test_cases.each do |test_case|
              hash[test_case.key] = test_case
            end
          end
        end
      end
    end
  end
end

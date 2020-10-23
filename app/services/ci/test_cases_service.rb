# frozen_string_literal: true

module Ci
  class TestCasesService
    MAX_TRACKABLE_FAILURES = 200

    def execute(build)
      return unless Feature.enabled?(:test_failure_history, build.project)
      return unless build.has_test_reports?
      return unless build.project.default_branch_or_master == build.ref

      test_suite = generate_test_suite_report(build)

      track_failures(build, test_suite)
    end

    private

    def generate_test_suite_report(build)
      build.collect_test_reports!(Gitlab::Ci::Reports::TestReports.new)
    end

    def track_failures(build, test_suite)
      return if test_suite.failed_count > MAX_TRACKABLE_FAILURES

      test_suite.failed.keys.each_slice(100) do |keys|
        Ci::TestCase.transaction do
          test_cases = Ci::TestCase.find_or_create_by_batch(build.project, keys)
          Ci::TestCaseFailure.insert_all(test_case_failures(test_cases, build))
        end
      end
    end

    def test_case_failures(test_cases, build)
      test_cases.map do |test_case|
        {
          test_case_id: test_case.id,
          build_id: build.id,
          failed_at: build.finished_at
        }
      end
    end
  end
end

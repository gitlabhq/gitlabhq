# frozen_string_literal: true

module Ci
  class BuildReportResultService
    def execute(build)
      return unless Feature.enabled?(:build_report_summary, build.project)
      return unless build.has_test_reports?

      build.report_results.create!(
        project_id: build.project_id,
        data: tests_params(build)
      )
    end

    private

    def generate_test_suite_report(build)
      build.collect_test_reports!(Gitlab::Ci::Reports::TestReports.new)
    end

    def tests_params(build)
      test_suite = generate_test_suite_report(build)

      {
        tests: {
          name: test_suite.name,
          duration: test_suite.total_time,
          failed: test_suite.failed_count,
          errored: test_suite.error_count,
          skipped: test_suite.skipped_count,
          success: test_suite.success_count
        }
      }
    end
  end
end

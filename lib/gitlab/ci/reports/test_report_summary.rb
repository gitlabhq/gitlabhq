# frozen_string_literal: true

module Gitlab
  module Ci
    module Reports
      class TestReportSummary
        def initialize(build_report_results)
          @build_report_results = build_report_results
          @suite_summary = TestSuiteSummary.new(@build_report_results)
        end

        def total
          @suite_summary.to_h
        end

        def test_suites
          @build_report_results
            .group_by(&:tests_name)
            .transform_values { |results| TestSuiteSummary.new(results) }
        end
      end
    end
  end
end

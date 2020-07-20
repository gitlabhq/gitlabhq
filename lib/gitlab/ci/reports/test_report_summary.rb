# frozen_string_literal: true

module Gitlab
  module Ci
    module Reports
      class TestReportSummary
        attr_reader :all_results

        def initialize(all_results)
          @all_results = all_results
        end

        def total
          TestSuiteSummary.new(all_results)
        end

        def total_time
          total.total_time
        end

        def total_count
          total.total_count
        end

        def success_count
          total.success_count
        end

        def failed_count
          total.failed_count
        end

        def skipped_count
          total.skipped_count
        end

        def error_count
          total.error_count
        end

        def test_suites
          all_results
            .group_by(&:tests_name)
            .transform_values { |results| TestSuiteSummary.new(results) }
        end
      end
    end
  end
end

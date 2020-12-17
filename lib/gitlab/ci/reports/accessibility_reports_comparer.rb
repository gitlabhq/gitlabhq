# frozen_string_literal: true

module Gitlab
  module Ci
    module Reports
      class AccessibilityReportsComparer < ReportsComparer
        def initialize(base_report, head_report)
          @base_report = base_report || AccessibilityReports.new
          @head_report = head_report
        end

        def success?
          head_report.errors_count == 0
        end

        def existing_errors
          strong_memoize(:existing_errors) do
            base_report.all_errors & head_report.all_errors
          end
        end

        def new_errors
          strong_memoize(:new_errors) do
            head_report.all_errors - base_report.all_errors
          end
        end

        def resolved_errors
          strong_memoize(:resolved_errors) do
            base_report.all_errors - head_report.all_errors
          end
        end

        def resolved_count
          resolved_errors.size
        end

        def total_count
          head_report.errors_count
        end

        alias_method :errors_count, :total_count
      end
    end
  end
end

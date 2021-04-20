# frozen_string_literal: true

module Gitlab
  module Ci
    module Reports
      class CodequalityReportsComparer < ReportsComparer
        def initialize(base_report, head_report)
          @base_report = base_report
          @head_report = head_report

          unless not_found?
            @base_report.sort_degradations!
            @head_report.sort_degradations!
          end
        end

        def success?
          head_report.degradations_count == 0
        end

        def existing_errors
          strong_memoize(:existing_errors) do
            next [] if not_found?

            base_report.all_degradations & head_report.all_degradations
          end
        end

        def new_errors
          strong_memoize(:new_errors) do
            next [] if not_found?

            fingerprints = head_report.degradations.keys - base_report.degradations.keys
            head_report.degradations.fetch_values(*fingerprints)
          end
        end

        def resolved_errors
          strong_memoize(:resolved_errors) do
            next [] if not_found?

            fingerprints = base_report.degradations.keys - head_report.degradations.keys
            base_report.degradations.fetch_values(*fingerprints)
          end
        end

        def resolved_count
          resolved_errors.size
        end

        def total_count
          head_report.degradations_count
        end

        alias_method :errors_count, :total_count
      end
    end
  end
end

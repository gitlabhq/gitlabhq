# frozen_string_literal: true

module Gitlab
  module Ci
    module Reports
      class TestSuiteSummary
        def initialize(build_report_results)
          @build_report_results = build_report_results
        end

        def name
          @name ||= @build_report_results.first.tests_name
        end

        # rubocop: disable CodeReuse/ActiveRecord
        def build_ids
          @build_report_results.pluck(:build_id)
        end

        def total_time
          @total_time ||= @build_report_results.sum(&:tests_duration)
        end

        def success_count
          @success_count ||= @build_report_results.sum(&:tests_success)
        end

        def failed_count
          @failed_count ||= @build_report_results.sum(&:tests_failed)
        end

        def skipped_count
          @skipped_count ||= @build_report_results.sum(&:tests_skipped)
        end

        def error_count
          @error_count ||= @build_report_results.sum(&:tests_errored)
        end

        def total_count
          @total_count ||= [success_count, failed_count, skipped_count, error_count].sum
        end
        # rubocop: disable CodeReuse/ActiveRecord

        def to_h
          {
            time: total_time,
            count: total_count,
            success: success_count,
            failed: failed_count,
            skipped: skipped_count,
            error: error_count
          }
        end
      end
    end
  end
end

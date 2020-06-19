# frozen_string_literal: true

module Gitlab
  module Ci
    module Reports
      class TestSuiteSummary
        attr_reader :results

        def initialize(results)
          @results = results
        end

        def name
          @name ||= results.first.tests_name
        end

        # rubocop: disable CodeReuse/ActiveRecord
        def total_time
          @total_time ||= results.sum(&:tests_duration)
        end

        def success_count
          @success_count ||= results.sum(&:tests_success)
        end

        def failed_count
          @failed_count ||= results.sum(&:tests_failed)
        end

        def skipped_count
          @skipped_count ||= results.sum(&:tests_skipped)
        end

        def error_count
          @error_count ||= results.sum(&:tests_errored)
        end

        def total_count
          @total_count ||= [success_count, failed_count, skipped_count, error_count].sum
        end
        # rubocop: disable CodeReuse/ActiveRecord
      end
    end
  end
end

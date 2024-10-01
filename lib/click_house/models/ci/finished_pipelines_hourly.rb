# frozen_string_literal: true

module ClickHouse # rubocop:disable Gitlab/BoundedContexts -- Existing module
  module Models
    module Ci
      class FinishedPipelinesHourly < FinishedPipelinesBase
        TIME_BUCKETS_LIMIT = 1.week.in_hours.to_i + 1 # +1 to add some error margin

        def self.table_name
          'ci_finished_pipelines_hourly'
        end

        def self.time_window_valid?(from_time, to_time)
          (to_time - from_time) / 1.hour < TIME_BUCKETS_LIMIT
        end

        def self.validate_time_window(from_time, to_time)
          return if time_window_valid?(from_time, to_time)

          "Maximum of #{TIME_BUCKETS_LIMIT} hours can be requested"
        end
      end
    end
  end
end

# frozen_string_literal: true

module ClickHouse # rubocop:disable Gitlab/BoundedContexts -- Existing module
  module Models
    module Ci
      class FinishedPipelinesDaily < FinishedPipelinesBase
        TIME_BUCKETS_LIMIT = 366

        def self.table_name
          'ci_finished_pipelines_daily'
        end

        def self.time_window_valid?(from_time, to_time)
          (to_time - from_time) / 1.day <= TIME_BUCKETS_LIMIT
        end

        def self.validate_time_window(from_time, to_time)
          return if time_window_valid?(from_time, to_time)

          "Maximum of #{TIME_BUCKETS_LIMIT} days can be requested"
        end
      end
    end
  end
end

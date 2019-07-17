# frozen_string_literal: true

# This module adds additional performance metrics to the grape logger
module Gitlab
  module GrapeLogging
    module Loggers
      class PerfLogger < ::GrapeLogging::Loggers::Base
        def parameters(_, _)
          gitaly_data.merge(rugged_data)
        end

        def gitaly_data
          gitaly_calls = Gitlab::GitalyClient.get_request_count

          return {} if gitaly_calls.zero?

          {
            gitaly_calls: Gitlab::GitalyClient.get_request_count,
            gitaly_duration: Gitlab::GitalyClient.query_time_ms
          }
        end

        def rugged_data
          rugged_calls = Gitlab::RuggedInstrumentation.query_count

          return {} if rugged_calls.zero?

          {
            rugged_calls: rugged_calls,
            rugged_duration_ms: Gitlab::RuggedInstrumentation.query_time_ms
          }
        end
      end
    end
  end
end

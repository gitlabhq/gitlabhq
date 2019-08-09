# frozen_string_literal: true

module Gitlab
  module InstrumentationHelper
    extend self

    KEYS = %i(gitaly_calls gitaly_duration rugged_calls rugged_duration_ms).freeze

    def add_instrumentation_data(payload)
      gitaly_calls = Gitlab::GitalyClient.get_request_count

      if gitaly_calls > 0
        payload[:gitaly_calls] = gitaly_calls
        payload[:gitaly_duration] = Gitlab::GitalyClient.query_time_ms
      end

      rugged_calls = Gitlab::RuggedInstrumentation.query_count

      if rugged_calls > 0
        payload[:rugged_calls] = rugged_calls
        payload[:rugged_duration_ms] = Gitlab::RuggedInstrumentation.query_time_ms
      end
    end
  end
end

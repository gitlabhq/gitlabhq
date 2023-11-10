# frozen_string_literal: true

module Gitlab
  module Graphql
    module Tracers
      # This graphql-ruby tracer records duration for trace events and merges
      # the duration into the trace event's metadata. This way, separate tracers
      # can all use the same duration information.
      #
      # NOTE: TimerTracer should be applied last **after** other tracers, so
      # that it runs first (similar to function composition)
      class TimerTracer
        def self.use(schema)
          schema.tracer(self.new)
        end

        def trace(key, data)
          start_time = ::Gitlab::Metrics::System.monotonic_time

          yield
        ensure
          data[:duration_s] = ::Gitlab::Metrics::System.monotonic_time - start_time
        end
      end
    end
  end
end

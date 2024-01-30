# frozen_string_literal: true

module Gitlab
  module Metrics
    class RuntimeLimiter
      delegate :monotonic_time, to: :'Gitlab::Metrics::System'

      DEFAULT_MAX_RUNTIME = 200.seconds

      attr_reader :max_runtime, :start_time

      def initialize(max_runtime = DEFAULT_MAX_RUNTIME)
        @start_time = monotonic_time
        @max_runtime = max_runtime
      end

      def elapsed_time
        monotonic_time - start_time
      end

      def over_time?
        @last_check = elapsed_time >= max_runtime
      end

      def was_over_time?
        !!@last_check
      end
    end
  end
end

# frozen_string_literal: true

module Gitlab
  module Utils
    class ExecutionTracker
      MAX_RUNTIME = 60.seconds

      ExecutionTimeOutError = Class.new(StandardError)

      delegate :monotonic_time, to: :'Gitlab::Metrics::System'

      def initialize(max_runtime = MAX_RUNTIME)
        @start_time = monotonic_time
        @max_runtime = max_runtime
      end

      def over_limit?
        monotonic_time - start_time >= max_runtime
      end

      private

      attr_reader :start_time, :max_runtime
    end
  end
end

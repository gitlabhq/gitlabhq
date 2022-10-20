# frozen_string_literal: true

module Gitlab
  module Utils
    class ExecutionTracker
      MAX_RUNTIME = 60.seconds

      ExecutionTimeOutError = Class.new(StandardError)

      delegate :monotonic_time, to: :'Gitlab::Metrics::System'

      def initialize
        @start_time = monotonic_time
      end

      def over_limit?
        monotonic_time - start_time >= MAX_RUNTIME
      end

      private

      attr_reader :start_time
    end
  end
end

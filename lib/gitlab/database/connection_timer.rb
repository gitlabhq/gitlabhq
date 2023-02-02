# frozen_string_literal: true

module Gitlab
  module Database
    class ConnectionTimer
      DEFAULT_INTERVAL = 3600
      RANDOMIZATION_INTERVAL = 600

      class << self
        def configure
          yield self
        end

        def starting_now
          # add a small amount of randomization to the interval, so reconnects don't all occur at once
          new(interval_with_randomization, current_clock_value)
        end

        attr_writer :interval

        def interval
          @interval ||= DEFAULT_INTERVAL
        end

        def interval_with_randomization
          interval + rand(RANDOMIZATION_INTERVAL) if interval > 0
        end

        def current_clock_value
          Process.clock_gettime(Process::CLOCK_MONOTONIC)
        end
      end

      attr_reader :interval, :starting_clock_value

      def initialize(interval, starting_clock_value)
        @interval = interval
        @starting_clock_value = starting_clock_value
      end

      def expired?
        interval&.positive? && self.class.current_clock_value > (starting_clock_value + interval)
      end

      def reset!
        @starting_clock_value = self.class.current_clock_value
      end
    end
  end
end

module Gitlab
  module Metrics
    # Class that sends certain metrics to InfluxDB at a specific interval.
    #
    # This class is used to gather statistics that can't be directly associated
    # with a transaction such as system memory usage, garbage collection
    # statistics, etc.
    class PrometheusSamples
      # interval - The sampling interval in seconds.
      def initialize(interval = Metrics.settings[:sample_interval])
        interval_half = interval.to_f / 2

        @interval = interval
        @interval_steps = (-interval_half..interval_half).step(0.1).to_a
      end

      def start
        Thread.new do
          Thread.current.abort_on_exception = true

          loop do
            sleep(sleep_interval)

            sample
          end
        end
      end

      def sidekiq?
        Sidekiq.server?
      end

      # Returns the sleep interval with a random adjustment.
      #
      # The random adjustment is put in place to ensure we:
      #
      # 1. Don't generate samples at the exact same interval every time (thus
      #    potentially missing anything that happens in between samples).
      # 2. Don't sample data at the same interval two times in a row.
      def sleep_interval
        while step = @interval_steps.sample
          if step != @last_step
            @last_step = step

            return @interval + @last_step
          end
        end
      end
    end
  end
end

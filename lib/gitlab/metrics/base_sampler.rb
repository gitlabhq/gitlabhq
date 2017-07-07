require 'logger'
module Gitlab
  module Metrics
    class BaseSampler
      def self.initialize_instance(*args)
        raise "#{name} singleton instance already initialized" if @instance
        @instance = new(*args)
        at_exit(&@instance.method(:stop))
        @instance
      end

      def self.instance
        @instance
      end

      attr_reader :running

      # interval - The sampling interval in seconds.
      def initialize(interval)
        interval_half = interval.to_f / 2

        @interval = interval
        @interval_steps = (-interval_half..interval_half).step(0.1).to_a

        @mutex = Mutex.new
      end

      def enabled?
        true
      end

      def start
        return unless enabled?

        @mutex.synchronize do
          return if running
          @running = true

          @thread = Thread.new do
            sleep(sleep_interval)

            while running
              safe_sample

              sleep(sleep_interval)
            end
          end
        end
      end

      def stop
        @mutex.synchronize do
          return unless running

          @running = false

          if @thread
            @thread.wakeup if @thread.alive?
            @thread.join
            @thread = nil
          end
        end
      end

      def safe_sample
        sample
      rescue => e
        Rails.logger.warn("#{self.class}: #{e}, stopping")
        stop
      end

      def sample
        raise NotImplementedError
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

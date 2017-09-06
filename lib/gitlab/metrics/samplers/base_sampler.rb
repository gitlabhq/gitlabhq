require 'logger'

module Gitlab
  module Metrics
    module Samplers
      class BaseSampler < Daemon
        # interval - The sampling interval in seconds.
        def initialize(interval)
          interval_half = interval.to_f / 2

          @interval = interval
          @interval_steps = (-interval_half..interval_half).step(0.1).to_a

          super()
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

        private

        attr_reader :running

        def start_working
          @running = true
          sleep(sleep_interval)
          while running
            safe_sample
            sleep(sleep_interval)
          end
        end

        def stop_working
          @running = false
        end
      end
    end
  end
end

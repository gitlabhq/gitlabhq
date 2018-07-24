module QA
  module Runtime
    module Wait
      class Timer
        TimeoutError = Class.new(StandardError)

        def initialize(timeout: nil)
          @end_time = current_time + timeout if timeout
          @remaining_time = @end_time - current_time if @end_time
        end

        def wait(timeout, &block)
          end_time = @end_time || current_time + timeout
          loop do
            yield(block)
            @remaining_time = end_time - current_time
            return if @remaining_time < 0
          end
          raise TimeoutError, "timed out after #{timeout} seconds"
        end

        def remaining_time
          @end_time - current_time
        end

        private

        if defined?(Process::CLOCK_MONOTONIC)
          def current_time
            Process.clock_gettime(Process::CLOCK_MONOTONIC)
          end
        else
          def current_time
            ::Time.now.to_f
          end
        end
      end

      class << self
        @default_timeout = 10 # seconds
        @default_interval = 1 # seconds
        @reload = false

        # hard sleep
        def sleep(timeout: nil, interval: nil, reload: false)
          interval ||= @default_interval
          timeout ||= @default_timeout
          reload ||= @reload

          start = Time.now

          while Time.now - start < timeout
            result = yield
            return result if result

            Kernel.sleep(interval)

            refresh if reload
          end

          false
        end

        def until(timeout: nil, interval: nil)
          timeout ||= @default_timeout
          run_with_timer(timeout, interval) do
            result = yield
            break result if result
          end
        end

        private

        def run_with_timer(timeout, interval, &block)
          return yield block if timeout.nil?

          timer.wait(timeout) do
            yield block
            Kernel.sleep interval || @default_interval
          end
        end
      end
    end
  end
end

module QA
  module Runtime
    module Wait
      class Timer
        attr_reader :end_time, :timeout
        TimeoutError = Class.new(StandardError)

        def initialize(timeout: Wait::DEFAULT_TIMEOUT)
          @timeout = timeout
          @end_time = current_time + timeout if timeout
          @remaining_time = @end_time - current_time if end_time
        end

        def wait(&block)
          loop do
            yield(block)
            return if remaining_time + timeout < 0
          end
          raise TimeoutError, "timed out after #{timeout} seconds"
        end

        def remaining_time
          end_time - current_time
        end

        private

        def current_time
          ::Time.now.to_f
        end
      end

      class << self
        DEFAULT_TIMEOUT = 10 # seconds
        DEFAULT_INTERVAL = 1 # seconds
        RELOAD = false

        # hard sleep
        def sleep(timeout: nil, interval: nil, reload: false)
          interval ||= DEFAULT_INTERVAL
          timeout ||= DEFAULT_TIMEOUT
          reload ||= RELOAD

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
          timeout ||= DEFAULT_TIMEOUT
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
            Kernel.sleep interval || DEFAULT_INTERVAL
          end
        end
      end
    end
  end
end

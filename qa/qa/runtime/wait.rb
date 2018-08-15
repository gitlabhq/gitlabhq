module QA
  module Runtime
    module Wait
      DEFAULT_TIMEOUT = 10 # seconds
      DEFAULT_INTERVAL = 1 # seconds
      RELOAD = false

      class Timer
        attr_reader :end_time, :timeout
        TimeoutError = Class.new(StandardError)

        def initialize(timeout: Wait::DEFAULT_TIMEOUT)
          @timeout = timeout
          @end_time = current_time + timeout if timeout
          @remaining_time = end_time - current_time if end_time
        end

        def wait(timeout, &block)
          time = current_time + timeout
          loop do
            yield block
            @remaining_time = time - current_time
            raise TimeoutError, "Timed out after #{timeout} seconds" if @remaining_time < 0
          end
        end

        def reset!
          @end_time = nil
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
        def timer
          @timer ||= Timer.new
        end

        # hard sleep
        def sleep(timeout: nil, interval: nil, reload: false)
          interval ||= DEFAULT_INTERVAL
          timeout ||= DEFAULT_TIMEOUT
          reload ||= RELOAD

          start = Time.now

          while Time.now - start < timeout

            if block_given?
              result = yield
              return result if result
            end

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
          if timeout.zero?
            yield block
          else
            timer.wait(timeout) do
              yield block
              sleep(timeout: timeout, interval: interval)
            end
          end
        end
      end
    end
  end
end

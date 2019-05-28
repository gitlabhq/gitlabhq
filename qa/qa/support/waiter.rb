# frozen_string_literal: true

module QA
  module Support
    module Waiter
      DEFAULT_MAX_WAIT_TIME = 60

      module_function

      def wait(max: DEFAULT_MAX_WAIT_TIME, interval: 0.1)
        QA::Runtime::Logger.debug("with wait: max #{max}; interval #{interval}")
        start = Time.now

        while Time.now - start < max
          result = yield
          if result
            log_end(Time.now - start)
            return result
          end

          sleep(interval)
        end
        log_end(Time.now - start)

        false
      end

      def self.log_end(duration)
        QA::Runtime::Logger.debug("ended wait after #{duration} seconds")
      end
    end
  end
end

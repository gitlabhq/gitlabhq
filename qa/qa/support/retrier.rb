# frozen_string_literal: true

module QA
  module Support
    module Retrier
      extend Repeater

      module_function

      def retry_on_exception(max_attempts: 3, reload_page: nil, sleep_interval: 0.5)
        QA::Runtime::Logger.debug(
          <<~MSG.tr("\n", ' ')
            with retry_on_exception: max_attempts: #{max_attempts};
            reload_page: #{reload_page};
            sleep_interval: #{sleep_interval}
        MSG
        )

        result = nil
        repeat_until(
          max_attempts: max_attempts,
          reload_page: reload_page,
          sleep_interval: sleep_interval,
          retry_on_exception: true
        ) do
          result = yield

          # This method doesn't care what the return value of the block is.
          # We set it to `true` so that it doesn't repeat if there's no exception
          true
        end
        QA::Runtime::Logger.debug("ended retry_on_exception")

        result
      end

      def retry_until(max_attempts: nil, max_duration: nil, reload_page: nil, sleep_interval: 0, raise_on_failure: false, retry_on_exception: false)
        # For backwards-compatibility
        max_attempts = 3 if max_attempts.nil? && max_duration.nil?

        start_msg ||= ["with retry_until:"]
        start_msg << "max_attempts: #{max_attempts};" if max_attempts
        start_msg << "max_duration: #{max_duration};" if max_duration
        start_msg << "reload_page: #{reload_page}; sleep_interval: #{sleep_interval}; raise_on_failure: #{raise_on_failure}; retry_on_exception: #{retry_on_exception}"
        QA::Runtime::Logger.debug(start_msg.join(' '))

        result = nil
        repeat_until(
          max_attempts: max_attempts,
          max_duration: max_duration,
          reload_page: reload_page,
          sleep_interval: sleep_interval,
          raise_on_failure: raise_on_failure,
          retry_on_exception: retry_on_exception
        ) do
          result = yield
        end
        QA::Runtime::Logger.debug("ended retry_until")

        result
      end
    end
  end
end

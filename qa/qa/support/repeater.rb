# frozen_string_literal: true

require 'active_support/inflector'

module QA
  module Support
    module Repeater
      DEFAULT_MAX_WAIT_TIME = 60

      RetriesExceededError = Class.new(RuntimeError)
      WaitExceededError = Class.new(RuntimeError)

      def repeat_until(max_attempts: nil, max_duration: nil, reload_page: nil, sleep_interval: 0, raise_on_failure: true, retry_on_exception: false)
        attempts = 0
        start = Time.now

        begin
          while remaining_attempts?(attempts, max_attempts) && remaining_time?(start, max_duration)
            QA::Runtime::Logger.debug("Attempt number #{attempts + 1}") if max_attempts

            result = yield
            return result if result

            sleep_and_reload_if_needed(sleep_interval, reload_page)
            attempts += 1
          end
        rescue StandardError, RSpec::Expectations::ExpectationNotMetError
          raise unless retry_on_exception

          attempts += 1
          if remaining_attempts?(attempts, max_attempts) && remaining_time?(start, max_duration)
            sleep_and_reload_if_needed(sleep_interval, reload_page)

            retry
          else
            raise
          end
        end

        if raise_on_failure
          raise RetriesExceededError, "Retry condition not met after #{max_attempts} #{'attempt'.pluralize(max_attempts)}" unless remaining_attempts?(attempts, max_attempts)

          raise WaitExceededError, "Wait condition not met after #{max_duration} #{'second'.pluralize(max_duration)}"
        end

        false
      end

      private

      def sleep_and_reload_if_needed(sleep_interval, reload_page)
        sleep(sleep_interval)
        reload_page.refresh if reload_page
      end

      def remaining_attempts?(attempts, max_attempts)
        max_attempts ? attempts < max_attempts : true
      end

      def remaining_time?(start, max_duration)
        max_duration ? Time.now - start < max_duration : true
      end
    end
  end
end

# frozen_string_literal: true
require 'active_support/inflector'

module QA
  module Support
    module Repeater
      using Rainbow
      DEFAULT_MAX_WAIT_TIME = 60

      RepeaterConditionExceededError = Class.new(RuntimeError)
      RetriesExceededError = Class.new(RepeaterConditionExceededError)
      WaitExceededError = Class.new(RepeaterConditionExceededError)

      def repeat_until(
        max_attempts: nil,
        max_duration: nil,
        reload_page: nil,
        sleep_interval: 0,
        raise_on_failure: true,
        retry_on_exception: false,
        log: true,
        message: nil
      )
        attempts = 0
        start = Time.now

        begin
          while remaining_attempts?(attempts, max_attempts) && remaining_time?(start, max_duration)
            # start logging from the second attempt
            if log && attempts == 1
              msg = ["Retrying action with:"]
              msg << "max_attempts: #{max_attempts};" if max_attempts
              msg << "max_duration: #{max_duration};" if max_duration
              msg << "reload_page: #{reload_page};" if reload_page
              msg << "sleep_interval: #{sleep_interval};"
              msg << "raise_on_failure: #{raise_on_failure};"
              msg << "retry_on_exception: #{retry_on_exception}"

              QA::Runtime::Logger.debug(msg.join(' '))
            end

            if log && max_attempts && attempts > 0
              QA::Runtime::Logger.debug("Attempt number #{attempts + 1}".bg(:yellow).black)
            end

            result = yield
            if result
              log_completion(log, attempts)
              return result
            end

            sleep_and_reload_if_needed(sleep_interval, reload_page)
            attempts += 1
          end
        rescue StandardError, RSpec::Expectations::ExpectationNotMetError => e
          raise unless retry_on_exception

          attempts += 1
          raise unless remaining_attempts?(attempts, max_attempts) && remaining_time?(start, max_duration)

          QA::Runtime::Logger.debug("Retry block rescued following error: #{e}, trying again...")
          sleep_and_reload_if_needed(sleep_interval, reload_page)
          retry
        end

        if raise_on_failure
          unless remaining_attempts?(attempts, max_attempts)
            raise(
              RetriesExceededError,
              "#{message || 'Retry'} failed after #{max_attempts} #{'attempt'.pluralize(max_attempts)}"
            )
          end

          raise(
            WaitExceededError,
            "#{message || 'Wait'} failed after #{max_duration} #{'second'.pluralize(max_duration)}"
          )
        end

        log_completion(log, attempts)

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

      # Log completion if more than one attempt performed
      #
      # @param [Boolean] log
      # @param [Integer] attempts
      # @return [void]
      def log_completion(log, attempts)
        return unless log && attempts > 0

        QA::Runtime::Logger.debug('ended retry')
      end
    end
  end
end

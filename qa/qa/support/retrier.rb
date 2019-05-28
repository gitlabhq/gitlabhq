# frozen_string_literal: true

module QA
  module Support
    module Retrier
      module_function

      def retry_on_exception(max_attempts: 3, reload_page: nil, sleep_interval: 0.5)
        QA::Runtime::Logger.debug("with retry_on_exception: max_attempts #{max_attempts}; sleep_interval #{sleep_interval}")

        attempts = 0

        begin
          QA::Runtime::Logger.debug("Attempt number #{attempts + 1}")
          yield
        rescue StandardError, RSpec::Expectations::ExpectationNotMetError
          sleep sleep_interval
          reload_page.refresh if reload_page
          attempts += 1

          retry if attempts < max_attempts
          QA::Runtime::Logger.debug("Raising exception after #{max_attempts} attempts")
          raise
        end
      end
    end
  end
end

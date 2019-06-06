# frozen_string_literal: true

module QA
  module CE
    module Strategy
      extend self

      def extend_autoloads!
        # noop
      end

      def perform_before_hooks
        retries ||= 0

        # The login page could take some time to load the first time it is visited.
        # We visit the login page and wait for it to properly load only once before the tests.
        QA::Runtime::Browser.visit(:gitlab, QA::Page::Main::Login)
      rescue QA::Page::Validatable::PageValidationError
        if (retries += 1) < 3
          Runtime::Logger.warn("The login page did not appear as expected. Retrying... (attempt ##{retries})")
          retry
        end

        raise
      end
    end
  end
end

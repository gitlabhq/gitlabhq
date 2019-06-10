# frozen_string_literal: true

module QA
  module CE
    module Strategy
      extend self

      def extend_autoloads!
        # noop
      end

      def perform_before_hooks
        # The login page could take some time to load the first time it is visited.
        # We visit the login page and wait for it to properly load only once before the tests.
        QA::Support::Retrier.retry_on_exception do
          QA::Runtime::Browser.visit(:gitlab, QA::Page::Main::Login)
        end
      end
    end
  end
end

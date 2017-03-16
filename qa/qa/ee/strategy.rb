module QA
  module EE
    module Strategy
      extend self
      def extend_autoloads!
        require 'qa/ee'
      end

      def perform_before_hooks
        EE::Scenario::License::Add.perform
      rescue
        Capybara::Screenshot.screenshot_and_save_page
        raise
      end
    end
  end
end

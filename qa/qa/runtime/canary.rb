# frozen_string_literal: true

module QA
  module Runtime
    module Canary
      CanaryValidationError = Class.new(StandardError)

      def validate_canary!
        return unless QA::Runtime::Env.qa_cookies.to_s.include?("gitlab_canary=true")

        canary_cookie = Capybara.current_session.driver.browser.manage.all_cookies.find do |cookie|
          cookie[:name] == 'gitlab_canary'
        end

        unless canary_cookie && canary_cookie[:value] == 'true'
          raise Canary::CanaryValidationError,
            "gitlab_canary=true cookie was expected but not set in browser. QA_COOKIES: #{QA::Runtime::Env.qa_cookies}"
        end

        return if Page::Main::Menu.perform(&:canary?)

        raise Canary::CanaryValidationError,
          "gitlab_canary=true cookie was set in browser but 'Next' badge was not shown on UI"
      end
    end
  end
end

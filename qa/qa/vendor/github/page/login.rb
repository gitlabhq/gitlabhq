# frozen_string_literal: true

require 'capybara/dsl'

module QA
  module Vendor
    module Github
      module Page
        class Login < Page::Base
          def login
            fill_in 'login', with: QA::Runtime::Env.github_username
            fill_in 'password', with: QA::Runtime::Env.github_password
            click_on 'Sign in'

            Support::Retrier.retry_until(raise_on_failure: true, sleep_interval: 35) do
              otp = OnePassword::CLI.new.otp

              fill_in 'otp', with: otp

              click_on 'Verify'

              !has_text?('Two-factor authentication failed', wait: 1.0)
            end

            click_on 'Authorize gitlab-qa' if has_button?('Authorize gitlab-qa')
          end
        end
      end
    end
  end
end

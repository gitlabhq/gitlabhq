# frozen_string_literal: true

require 'capybara/dsl'
require 'benchmark'

module QA
  module Vendor
    module Github
      module Page
        class Login < Page::Base
          def login
            fill_in 'login', with: QA::Runtime::Env.github_username
            fill_in 'password', with: QA::Runtime::Env.github_password
            click_on 'Sign in'

            current_otp = OnePassword::CLI.instance.current_otp

            fill_in 'app_otp', with: current_otp

            if has_text?('Two-factor authentication failed', wait: 2)
              new_otp = OnePassword::CLI.instance.new_otp(otp)

              fill_in 'app_otp', with: new_otp
            end

            authorize_app
          end

          def authorize_app
            click_on 'Authorize' if has_button?('Authorize')
          end
        end
      end
    end
  end
end

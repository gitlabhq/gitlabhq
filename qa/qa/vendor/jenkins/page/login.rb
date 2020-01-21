# frozen_string_literal: true

require 'capybara/dsl'

module QA
  module Vendor
    module Jenkins
      module Page
        class Login < Page::Base
          def initialize
            @path = 'login'
          end

          def visit!
            super

            QA::Support::Retrier.retry_until(sleep_interval: 3, reload_page: page, max_attempts: 20, raise_on_failure: true) do
              page.has_text? 'Welcome to Jenkins!'
            end
          end

          def login
            fill_in 'j_username', with: 'admin'
            fill_in 'j_password', with: 'password'
            click_on 'Sign in'
          end
        end
      end
    end
  end
end

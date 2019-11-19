# frozen_string_literal: true

require 'capybara/dsl'

module QA
  module Vendor
    module SAMLIdp
      module Page
        class Login < Page::Base
          def login(username, password)
            QA::Runtime::Logger.debug("Logging into SAMLIdp with username: #{username} and password:#{password}") if QA::Runtime::Env.debug?

            fill_in 'username', with: username
            fill_in 'password', with: password
            click_on 'Login'
          end

          def login_if_required(username, password)
            login(username, password) if login_required?
          end

          def login_required?
            login_required = page.has_text?('Enter your username and password')
            QA::Runtime::Logger.debug("login_required: #{login_required}") if QA::Runtime::Env.debug?
            login_required
          end
        end
      end
    end
  end
end

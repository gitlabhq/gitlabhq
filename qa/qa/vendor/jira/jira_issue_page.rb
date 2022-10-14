# frozen_string_literal: true

require 'capybara/dsl'

module QA
  module Vendor
    module Jira
      class JiraIssuePage < JiraAPI
        include Capybara::DSL
        include Scenario::Actable

        def login(username, password)
          QA::Runtime::Logger.debug("Logging into JIRA with username: #{username} and password:#{password}")

          fill_in 'login-form-username', with: username
          fill_in 'login-form-password', with: password
          click_on 'login-form-submit'
        end

        def go_to_login_page
          click_on 'log in'
        end

        def login_if_required(username, password)
          return unless login_required?

          go_to_login_page
          login(username, password)
        end

        def summary_field
          page.find('#summary').value
        end

        def issue_description
          page.find('#description', visible: false).value
        end

        def login_required?
          login_required = page.has_text?('You are not logged in')
          QA::Runtime::Logger.debug("login_required: #{login_required}")
          login_required
        end
      end
    end
  end
end

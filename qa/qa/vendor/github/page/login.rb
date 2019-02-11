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

            unless has_no_text?("Authorize GitLab-OAuth")
              click_on 'Authorize gitlab-qa' if has_button?('Authorize gitlab-qa')
            end
          end
        end
      end
    end
  end
end

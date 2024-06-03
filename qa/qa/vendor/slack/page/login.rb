# frozen_string_literal: true

module QA
  module Vendor
    module Slack
      module Page
        class Login < Vendor::Page::Base
          def self.path
            '/workspace-signin'
          end

          def sign_in
            navigate_to_workspace

            # sign in with password if needed
            password_link_text = 'sign in with a password instead'
            click_link(password_link_text) if has_link?(password_link_text)

            finish_sign_in
          end

          def navigate_to_workspace
            fill_in('domain', with: Runtime::Env.slack_workspace)
            click_button('Continue')
          end

          def finish_sign_in
            return unless has_field?('email')

            fill_in('email', with: Runtime::Env.slack_email)
            fill_in('password', with: Runtime::Env.slack_password)

            click_button('Sign In')
          end
        end
      end
    end
  end
end

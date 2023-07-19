# frozen_string_literal: true

module QA
  module Vendor
    module Facebook
      module Page
        class Login < Vendor::Page::Base
          def login
            fill_in 'email', with: QA::Runtime::Env.facebook_username
            fill_in 'pass', with: QA::Runtime::Env.facebook_password
            find('#loginbutton').click

            confirm_oauth_access
          end

          def confirm_oauth_access
            first('span', text: 'Continue as').click if has_css?('span', text: 'Continue as')
          end
        end
      end
    end
  end
end

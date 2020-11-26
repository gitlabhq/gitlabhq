# frozen_string_literal: true

module QA
  module Page
    module Admin
      module Settings
        module Component
          class SignUpRestrictions < Page::Base
            view 'app/views/admin/application_settings/_signup.html.haml' do
              element :require_admin_approval_after_user_signup_checkbox
              element :save_changes_button
            end

            def require_admin_approval_after_user_signup
              check_element :require_admin_approval_after_user_signup_checkbox
              click_element :save_changes_button
            end
          end
        end
      end
    end
  end
end

# frozen_string_literal: true

module QA
  module Page
    module Admin
      module Settings
        module Component
          class SignUpRestrictions < Page::Base
            view 'app/assets/javascripts/pages/admin/application_settings/general/components/signup_form.vue' do
              element :require_admin_approval_after_user_signup_checkbox
              element :signup_enabled_checkbox
              element :save_changes_button
            end

            def require_admin_approval_after_user_signup
              click_element_coordinates(:require_admin_approval_after_user_signup_checkbox, visible: false)
              click_element(:save_changes_button)
            end

            def disable_signups
              click_element_coordinates(:signup_enabled_checkbox, visible: false)
              click_element(:save_changes_button)
            end
          end
        end
      end
    end
  end
end

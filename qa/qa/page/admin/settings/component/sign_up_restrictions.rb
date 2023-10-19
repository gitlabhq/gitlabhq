# frozen_string_literal: true

module QA
  module Page
    module Admin
      module Settings
        module Component
          class SignUpRestrictions < Page::Base
            view 'app/assets/javascripts/pages/admin/application_settings/general/components/signup_form.vue' do
              element 'require-admin-approval-checkbox'
              element 'signup-enabled-checkbox'
              element 'save-changes-button'
            end

            def require_admin_approval_after_user_signup
              click_element_coordinates('require-admin-approval-after-user-signup-checkbox', visible: false)
              click_element('save-changes-button')
            end

            def disable_signups
              click_element_coordinates('signup-enabled-checkbox', visible: false)
              click_element('save-changes-button')
            end
          end
        end
      end
    end
  end
end

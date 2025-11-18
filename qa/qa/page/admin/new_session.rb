# frozen_string_literal: true

module QA
  module Page
    module Admin
      class NewSession < Page::Base
        view 'app/views/devise/sessions/_new_base.html.haml' do
          element 'admin-sign-in-button'
          element 'admin-password-field'
        end

        def set_password(password)
          fill_element 'admin-password-field', password
        end

        def click_enter_admin_mode
          click_element 'admin-sign-in-button'
        end
      end
    end
  end
end

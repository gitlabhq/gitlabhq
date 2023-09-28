# frozen_string_literal: true

module QA
  module Page
    module Admin
      class NewSession < Page::Base
        view 'app/views/admin/sessions/_new_base.html.haml' do
          element 'enter-admin-mode-button'
          element 'password-field'
        end

        def set_password(password)
          fill_element 'password-field', password
        end

        def click_enter_admin_mode
          click_element 'enter-admin-mode-button'
        end
      end
    end
  end
end

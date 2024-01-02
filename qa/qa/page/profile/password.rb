# frozen_string_literal: true

module QA
  module Page
    module Profile
      class Password < Page::Base
        view 'app/views/user_settings/passwords/edit.html.haml' do
          element 'current-password-field'
          element 'new-password-field'
          element 'confirm-password-field'
          element 'save-password-button'
        end

        view 'app/views/user_settings/passwords/new.html.haml' do
          element 'current-password-field'
          element 'new-password-field'
          element 'confirm-password-field'
          element 'set-new-password-button'
        end

        def update_password(new_password, current_password)
          find_element('current-password-field').set current_password
          find_element('new-password-field').set new_password
          find_element('confirm-password-field').set new_password
          click_element('save-password-button')
        end

        def set_new_password(new_password, current_password)
          fill_element('current-password-field', current_password)
          fill_element('new-password-field', new_password)
          fill_element('confirm-password-field', new_password)
          click_element('set-new-password-button')
        end
      end
    end
  end
end

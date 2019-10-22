# frozen_string_literal: true

module QA
  module Page
    module Profile
      class Password < Page::Base
        view 'app/views/profiles/passwords/edit.html.haml' do
          element :current_password_field
          element :new_password_field
          element :confirm_password_field
          element :save_password_button
        end

        def update_password(new_password, current_password)
          find_element(:current_password_field).set current_password
          find_element(:new_password_field).set new_password
          find_element(:confirm_password_field).set new_password
          click_element(:save_password_button)
        end
      end
    end
  end
end

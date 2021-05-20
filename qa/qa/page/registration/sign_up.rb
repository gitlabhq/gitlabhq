# frozen_string_literal: true

module QA
  module Page
    module Registration
      class SignUp < Page::Base
        view 'app/views/devise/shared/_signup_box.html.haml' do
          element :new_user_first_name_field
          element :new_user_last_name_field
          element :new_user_email_field
          element :new_user_password_field
          element :new_user_register_button
        end

        view 'app/helpers/registrations_helper.rb' do
          element :new_user_username_field
        end

        view 'app/views/registrations/welcome/show.html.haml' do
          element :get_started_button
        end

        def fill_new_user_first_name_field(first_name)
          fill_element :new_user_first_name_field, first_name
        end

        def fill_new_user_last_name_field(last_name)
          fill_element :new_user_last_name_field, last_name
        end

        def fill_new_user_username_field(username)
          fill_element :new_user_username_field, username
        end

        def fill_new_user_email_field(email)
          fill_element :new_user_email_field, email
        end

        def fill_new_user_password_field(password)
          fill_element :new_user_password_field, password
        end

        def click_new_user_register_button
          click_element :new_user_register_button if has_element?(:new_user_register_button)
        end
      end
    end
  end
end

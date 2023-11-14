# frozen_string_literal: true

module QA
  module Page
    module Registration
      class SignUp < Page::Base
        view 'app/views/devise/shared/_signup_box_form.html.haml' do
          element 'new-user-first-name-field'
          element 'new-user-last-name-field'
          element 'new-user-email-field'
          element 'new-user-password-field'
          element 'new-user-register-button'
        end

        view 'app/helpers/registrations_helper.rb' do
          element 'new-user-username-field'
        end

        def fill_new_user_first_name_field(first_name)
          fill_element 'new-user-first-name-field', first_name
        end

        def fill_new_user_last_name_field(last_name)
          fill_element 'new-user-last-name-field', last_name
        end

        def fill_new_user_username_field(username)
          fill_element 'new-user-username-field', username
        end

        def fill_new_user_email_field(email)
          fill_element 'new-user-email-field', email
        end

        def fill_new_user_password_field(password)
          fill_element 'new-user-password-field', password
        end

        def click_new_user_register_button
          click_element 'new-user-register-button' if has_element?('new-user-register-button')
        end
      end
    end
  end
end

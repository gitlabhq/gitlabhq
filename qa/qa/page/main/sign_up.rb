# frozen_string_literal: true

module QA
  module Page
    module Main
      class SignUp < Page::Base
        view 'app/views/devise/shared/_signup_box.html.haml' do
          element :new_user_name_field
          element :new_user_username_field
          element :new_user_email_field
          element :new_user_email_confirmation_field
          element :new_user_password_field
          element :new_user_register_button
          element :new_user_accept_terms_checkbox
        end

        def sign_up!(user)
          fill_element :new_user_name_field, user.name
          fill_element :new_user_username_field, user.username
          fill_element :new_user_email_field, user.email
          fill_element :new_user_email_confirmation_field, user.email
          fill_element :new_user_password_field, user.password

          check_element :new_user_accept_terms_checkbox if has_element?(:new_user_accept_terms_checkbox)

          signed_in = retry_until do
            click_element :new_user_register_button

            Page::Main::Menu.perform(&:has_personal_area?)
          end

          raise "Failed to register and sign in" unless signed_in
        end
      end
    end
  end
end

# frozen_string_literal: true

module QA
  module Page
    module Main
      class SignUp < Page::Base
        view 'app/views/devise/shared/_signup_box.html.haml' do
          element :new_user_name
          element :new_user_username
          element :new_user_email
          element :new_user_email_confirmation
          element :new_user_password
          element :new_user_register_button
          element :new_user_accept_terms
        end

        def sign_up!(user)
          fill_element :new_user_name, user.name
          fill_element :new_user_username, user.username
          fill_element :new_user_email, user.email
          fill_element :new_user_email_confirmation, user.email
          fill_element :new_user_password, user.password

          check_element :new_user_accept_terms if has_element?(:new_user_accept_terms)

          signed_in = retry_until do
            click_element :new_user_register_button

            Page::Main::Menu.act { has_personal_area? }
          end

          raise "Failed to register and sign in" unless signed_in
        end
      end
    end
  end
end

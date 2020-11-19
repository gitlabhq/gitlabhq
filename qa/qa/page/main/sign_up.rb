# frozen_string_literal: true

module QA
  module Page
    module Main
      class SignUp < Page::Base
        view 'app/views/devise/shared/_signup_box.html.haml' do
          element :new_user_first_name_field
          element :new_user_last_name_field
          element :new_user_username_field
          element :new_user_email_field
          element :new_user_password_field
          element :new_user_register_button
        end

        view 'app/views/registrations/welcome/show.html.haml' do
          element :get_started_button
        end

        def sign_up!(user)
          signed_in = retry_until(raise_on_failure: false) do
            fill_element :new_user_first_name_field, user.first_name
            fill_element :new_user_last_name_field, user.last_name
            fill_element :new_user_username_field, user.username
            fill_element :new_user_email_field, user.email
            fill_element :new_user_password_field, user.password
            click_element :new_user_register_button if has_element?(:new_user_register_button)
            click_element :get_started_button if has_element?(:get_started_button)

            Page::Main::Menu.perform(&:has_personal_area?)
          end

          raise "Failed to register and sign in" unless signed_in
        end
      end
    end
  end
end

QA::Page::Main::SignUp.prepend_if_ee('QA::EE::Page::Main::SignUp')

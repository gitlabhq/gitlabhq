module QA
  module Page
    module Main
      class SignUp < Page::Base
        view 'app/views/devise/shared/_signup_box.html.haml' do
          element :name, 'text_field :name'
          element :username, 'text_field :username'
          element :email_field, 'email_field :email'
          element :email_confirmation, 'email_field :email_confirmation'
          element :password, 'password_field :password'
          element :register_button, 'submit "Register"'
        end

        def sign_up!(user)
          fill_in :new_user_name, with: user.name
          fill_in :new_user_username, with: user.username
          fill_in :new_user_email, with: user.email
          fill_in :new_user_email_confirmation, with: user.email
          fill_in :new_user_password, with: user.password
          click_button 'Register'

          Page::Menu::Main.act { has_personal_area? }
        end
      end
    end
  end
end

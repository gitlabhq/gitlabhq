# frozen_string_literal: true

module QA
  module Page
    module Registration
      class SignUp < Page::Base
        view 'app/views/devise/registrations/_signup_box_form.html.haml' do
          element 'new-user-first-name-field'
          element 'new-user-last-name-field'
          element 'new-user-email-field'
          element 'new-user-register-button'
        end

        view 'app/views/devise/registrations/_password_input.html.haml' do
          element 'new-user-password-field'
        end

        view 'app/helpers/registrations_helper.rb' do
          element 'new-user-username-field'
        end

        def self.path
          '/users/sign_up'
        end

        # Register a user
        # @param [Resource::User] user the user to register
        def register_user(user)
          raise ArgumentError, 'User must be of type Resource::User' unless user.is_a? Resource::User

          fill_element 'new-user-first-name-field', user.first_name
          fill_element 'new-user-last-name-field', user.last_name
          fill_element 'new-user-username-field', user.username
          fill_element 'new-user-email-field', user.email
          fill_element 'new-user-password-field', user.password

          Support::Waiter.wait_until(sleep_interval: 0.5) do
            page.has_content?("Username is available.")

            network_password_requirements.each do |requirement|
              page_has_success_requirement?(requirement) if page.has_content?(requirement, wait: 0.5)
            end
          end

          click_element 'new-user-register-button' if has_element?('new-user-register-button')
        end

        private

        def network_password_requirements
          [
            'Cannot use common phrases (e.g. "password")',
            'Cannot include your name, username, or email'
          ]
        end

        def page_has_success_requirement?(requirement)
          has_element?('password-rule-text', class: 'gl-text-success', text: requirement)
        end
      end
    end
  end
end

# frozen_string_literal: true

module QA
  module Page
    module Profile
      class TwoFactorAuth < Page::Base
        view 'app/views/profiles/two_factor_auths/_configure_later_button.html.haml' do
          element 'configure-it-later-button'
        end

        view 'app/views/profiles/two_factor_auths/show.html.haml' do
          element 'otp-secret-content'
          element 'pin-code-field'
          element 'current-password-field'
          element 'register-2fa-app-button'
        end

        view 'app/assets/javascripts/authentication/two_factor_auth/components/recovery_codes.vue' do
          element 'proceed-button'
          element 'copy-button'
          element 'recovery-codes'
          element 'code-content'
        end

        def click_configure_it_later_button
          page.refresh

          click_element 'configure-it-later-button'
          wait_until(max_duration: 10, message: "Waiting for create a group page") do
            has_text?("Welcome to GitLab") && has_text?("Create a group")
          end
        end

        def otp_secret_content
          find_element('otp-secret-content').text.gsub('Key:', '').delete(' ')
        end

        def set_pin_code(pin_code)
          fill_element('pin-code-field', pin_code)
        end

        def set_current_password(password)
          fill_element('current-password-field', password)
        end

        def click_register_2fa_app_button
          click_element 'register-2fa-app-button'
        end

        def recovery_codes
          code_elements = within_element('recovery-codes') do
            all_elements('code-content', minimum: 1)
          end
          code_elements.map { |code_content| code_content.text }
        end

        def click_copy_and_proceed
          click_element 'copy-button'
          click_element 'proceed-button'
        end
      end
    end
  end
end

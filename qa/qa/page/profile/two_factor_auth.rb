# frozen_string_literal: true

module QA
  module Page
    module Profile
      class TwoFactorAuth < Page::Base
        view 'app/assets/javascripts/pages/profiles/two_factor_auths/index.js' do
          element :configure_it_later_button
        end

        view 'app/views/profiles/two_factor_auths/show.html.haml' do
          element :otp_secret_content
          element :pin_code_field
          element :register_2fa_app_button
        end

        view 'app/views/profiles/two_factor_auths/_codes.html.haml' do
          element :proceed_button
          element :codes_content
          element :code_content
        end

        def click_configure_it_later_button
          click_element :configure_it_later_button
        end

        def otp_secret_content
          find_element(:otp_secret_content).text.gsub('Key:', '').delete(' ')
        end

        def set_pin_code(pin_code)
          fill_element(:pin_code_field, pin_code)
        end

        def click_register_2fa_app_button
          click_element :register_2fa_app_button
        end

        def recovery_codes
          code_elements = within_element(:codes_content) do
            all_elements(:code_content, minimum: 1)
          end
          code_elements.map { |code_content| code_content.text }
        end

        def click_proceed_button
          click_element :proceed_button
        end
      end
    end
  end
end

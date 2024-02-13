# frozen_string_literal: true

module QA
  module Page
    module Main
      class TwoFactorAuth < Page::Base
        view 'app/views/devise/shared/_totp_recovery_code_or_webauthn.html.haml' do
          element 'verify-code-button'
          element 'two-fa-code-field'
        end

        def click_verify_code_button
          click_element 'verify-code-button'
        end

        def set_2fa_code(code)
          fill_element('two-fa-code-field', code)
        end
      end
    end
  end
end

# frozen_string_literal: true

module QA
  module Page
    module Main
      class TwoFactorAuth < Page::Base
        view 'app/views/devise/sessions/two_factor.html.haml' do
          element :verify_code_button
          element :two_fa_code_field
        end

        def click_verify_code_button
          click_element :verify_code_button
        end

        def set_2fa_code(code)
          fill_element(:two_fa_code_field, code)
        end
      end
    end
  end
end

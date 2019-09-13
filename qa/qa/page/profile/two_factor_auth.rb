# frozen_string_literal: true

module QA
  module Page
    module Profile
      class TwoFactorAuth < Page::Base
        view 'app/assets/javascripts/pages/profiles/two_factor_auths/index.js' do
          element :configure_it_later_button
        end

        def click_configure_it_later_button
          click_element :configure_it_later_button
        end
      end
    end
  end
end

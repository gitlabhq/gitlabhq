# frozen_string_literal: true

module QA
  module Page
    module Profile
      module Accounts
        class Show < Page::Base
          view 'app/views/profiles/accounts/show.html.haml' do
            element :delete_account_button, required: true
            element :enable_2fa_button
          end

          view 'app/assets/javascripts/profile/account/components/delete_account_modal.vue' do
            element :password_confirmation_field
            element :confirm_delete_account_button
          end

          def click_enable_2fa_button
            click_element(:enable_2fa_button)
          end

          def delete_account(password)
            click_element(:delete_account_button)

            find_element(:password_confirmation_field).set password
            click_element(:confirm_delete_account_button)
          end
        end
      end
    end
  end
end

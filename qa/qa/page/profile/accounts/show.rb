# frozen_string_literal: true

module QA
  module Page
    module Profile
      module Accounts
        class Show < Page::Base
          view 'app/views/profiles/accounts/show.html.haml' do
            element :delete_account_button, required: true
          end

          view 'app/assets/javascripts/profile/account/components/delete_account_modal.vue' do
            element :password_confirmation_field
          end

          view 'app/assets/javascripts/vue_shared/components/deprecated_modal.vue' do
            element :save_changes_button
          end

          def delete_account(password)
            click_element(:delete_account_button)

            find_element(:password_confirmation_field).set password
            click_element(:save_changes_button)
          end
        end
      end
    end
  end
end

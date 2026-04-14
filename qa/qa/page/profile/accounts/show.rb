# frozen_string_literal: true

module QA
  module Page
    module Profile
      module Accounts
        class Show < Page::Base
          view 'app/views/profiles/accounts/show.html.haml' do
            element 'delete-account-button', required: true
          end

          view 'app/assets/javascripts/profile/account/components/delete_account_modal.vue' do
            element 'password-confirmation-field'
            element 'confirm-delete-account-button'
          end

          def delete_account(password)
            click_element('delete-account-button')

            find_element('password-confirmation-field').set password
            click_element('confirm-delete-account-button')
          end
        end
      end
    end
  end
end

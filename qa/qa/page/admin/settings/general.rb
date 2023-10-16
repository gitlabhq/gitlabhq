# frozen_string_literal: true

module QA
  module Page
    module Admin
      module Settings
        class General < Page::Base
          include QA::Page::Settings::Common

          view 'app/views/admin/application_settings/general.html.haml' do
            element 'account-and-limit-settings-content'
            element 'sign-up-restrictions-settings-content'
          end

          def expand_account_and_limit(&block)
            expand_content('account-and-limit-settings-content') do
              Component::AccountAndLimit.perform(&block)
            end
          end

          def expand_sign_up_restrictions(&block)
            expand_content('sign-up-restrictions-settings-content') do
              Component::SignUpRestrictions.perform(&block)
            end
          end
        end
      end
    end
  end
end

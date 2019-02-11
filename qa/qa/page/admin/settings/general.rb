# frozen_string_literal: true

module QA
  module Page
    module Admin
      module Settings
        class General < Page::Base
          include QA::Page::Settings::Common

          view 'app/views/admin/application_settings/show.html.haml' do
            element :account_and_limit_settings
          end

          def expand_account_and_limit(&block)
            expand_section(:account_and_limit_settings) do
              Component::AccountAndLimit.perform(&block)
            end
          end
        end
      end
    end
  end
end

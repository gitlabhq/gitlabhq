# frozen_string_literal: true

module QA
  module Page
    module Profile
      module Preferences
        class Show < Page::Base
          view 'app/assets/javascripts/profile/preferences/components/extensions_marketplace_warning.vue' do
            element 'confirm-marketplace-acknowledgement'
          end

          def enable_extensions_marketplace
            check_element('#user_extensions_marketplace_enabled', true)

            # User only needs to confirm marketplace acknowledgment once, so won't always be present
            return unless has_element?('confirm-marketplace-acknowledgement', wait: 1)

            click_element('confirm-marketplace-acknowledgement')
          end

          def save_preferences
            click_element("button[type='submit']", text: 'Save changes')
          end
        end
      end
    end
  end
end

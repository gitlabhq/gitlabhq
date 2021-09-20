# frozen_string_literal: true

module QA
  module Page
    module Admin
      module Settings
        module Component
          class IpLimits < Page::Base
            view 'app/views/admin/application_settings/_ip_limits.html.haml' do
              element :throttle_unauthenticated_api_checkbox
              element :throttle_unauthenticated_web_checkbox
              element :throttle_authenticated_api_checkbox
              element :throttle_authenticated_web_checkbox
              element :save_changes_button
            end

            def enable_throttles
              check_element(:throttle_unauthenticated_api_checkbox, true)
              check_element(:throttle_unauthenticated_web_checkbox, true)
              check_element(:throttle_authenticated_api_checkbox, true)
              check_element(:throttle_authenticated_web_checkbox, true)
            end

            def save_settings
              click_element :save_changes_button
            end
          end
        end
      end
    end
  end
end

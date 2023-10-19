# frozen_string_literal: true

module QA
  module Page
    module Admin
      module Settings
        module Component
          class IpLimits < Page::Base
            view 'app/views/admin/application_settings/_ip_limits.html.haml' do
              element 'throttle-unauthenticated-api-checkbox'
              element 'throttle-unauthenticated-web-checkbox'
              element 'throttle-authenticated-api-checkbox'
              element 'throttle-authenticated-web-checkbox'
              element 'save-changes-button'
            end

            def enable_throttles
              check_element('throttle-unauthenticated-api-checkbox', true)
              check_element('throttle-unauthenticated-web-checkbox', true)
              check_element('throttle-authenticated-api-checkbox', true)
              check_element('throttle-authenticated-web-checkbox', true)
            end

            def save_settings
              click_element 'save-changes-button'
            end
          end
        end
      end
    end
  end
end

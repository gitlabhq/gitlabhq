# frozen_string_literal: true

module QA
  module Page
    module Admin
      module Settings
        module Component
          class IpLimits < Page::Base
            view 'app/views/admin/application_settings/_ip_limits.html.haml' do
              element 'throttle-authenticated-api-checkbox'
              element 'save-changes-button'
            end

            def enable_authenticated_api_request_limit
              check_element('throttle-authenticated-api-checkbox', true)
            end

            def set_authenticated_api_request_limit_per_user(limit)
              find_element('throttle-authenticated-api-requests-per-user').set('')
              fill_element 'throttle-authenticated-api-requests-per-user', limit
            end

            def set_authenticated_api_request_limit_seconds(seconds)
              find_element('throttle-authenticated-api-requests-per-seconds').set('')
              fill_element 'throttle-authenticated-api-requests-per-seconds', seconds
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

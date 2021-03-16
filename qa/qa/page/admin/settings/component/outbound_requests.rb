# frozen_string_literal: true

module QA
  module Page
    module Admin
      module Settings
        module Component
          class OutboundRequests < Page::Base
            view 'app/views/admin/application_settings/_outbound.html.haml' do
              element :allow_requests_from_services_checkbox
              element :save_changes_button
            end

            def allow_requests_to_local_network_from_services
              check_allow_requests_to_local_network_from_services_checkbox
              click_save_changes_button
            end

            private

            def check_allow_requests_to_local_network_from_services_checkbox
              check_element(:allow_requests_from_services_checkbox)
            end

            def click_save_changes_button
              click_element :save_changes_button
            end
          end
        end
      end
    end
  end
end

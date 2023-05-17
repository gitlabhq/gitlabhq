# frozen_string_literal: true

module QA
  module Page
    module Project
      module Settings
        class Alerts < Page::Base
          include ::QA::Page::Component::Dropdown

          view 'app/assets/javascripts/alerts_settings/components/alerts_form.vue' do
            element :create_incident_checkbox
            element :incident_templates_dropdown
            element :save_changes_button
            element :enable_email_notification_checkbox
          end

          view 'app/assets/javascripts/alerts_settings/components/alerts_settings_wrapper.vue' do
            element :add_integration_button
          end

          view 'app/assets/javascripts/alerts_settings/components/alerts_settings_form.vue' do
            element :integration_type_dropdown
            element :integration_name_field
            element :active_toggle_container
            element :save_and_create_alert_button
            element :test_payload_field
            element :send_test_alert_button
            element :prometheus_url_field
          end

          def go_to_alert_settings
            click_link_with_text('Alert settings')
          end

          def enable_incident_for_alert
            check_element(:create_incident_checkbox, true)
          end

          def enable_email_notification
            check_element(:enable_email_notification_checkbox, true)
          end

          def select_issue_template(template)
            click_element(:incident_templates_dropdown)
            within_element :incident_templates_dropdown do
              select_item(template)
            end
          end

          def save_alert_settings
            click_element :save_changes_button
          end

          def has_template?(template)
            within_element :incident_templates_dropdown do
              has_text?(template)
            end
          end

          def add_new_integration
            wait_for_requests
            click_element(:add_integration_button)
          end

          def select_http_endpoint
            click_element(:integration_type_dropdown)
            find("option[value='HTTP']").click

            # Click outside of the list to close it
            click_element(:integration_name_field)
          end

          def select_prometheus
            click_element(:integration_type_dropdown)
            find("option[value='PROMETHEUS']").click

            # Click outside of the list to close it
            click_element(:prometheus_url_field)
          end

          def enter_integration_name(name)
            fill_element(:integration_name_field, name)
          end

          def fill_in_prometheus_url(url = Runtime::Scenario.gitlab_address)
            fill_element(:prometheus_url_field, url)
          end

          def activate_integration
            within_element(:active_toggle_container) do
              find('.gl-toggle').click
            end

            wait_for_requests
          end

          def save_and_create_alert
            click_element(:save_and_create_alert_button)
          end

          def fill_in_test_payload(payload)
            fill_element(:test_payload_field, payload)
          end

          def send_test_alert
            click_element(:send_test_alert_button)
          end

          def go_to_view_credentials
            click_link_with_text('View credentials')
          end

          def webhook_url
            find('input[id="url"]').value
          end

          def authorization_key
            find('input[id="authorization-key"]').value
          end
        end
      end
    end
  end
end

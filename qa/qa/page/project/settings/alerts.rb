# frozen_string_literal: true

module QA
  module Page
    module Project
      module Settings
        class Alerts < Page::Base
          include ::QA::Page::Component::Dropdown

          view 'app/assets/javascripts/alerts_settings/components/alerts_form.vue' do
            element 'create-incident-checkbox'
            element 'incident-templates-dropdown'
            element 'save-changes-button'
            element 'enable-email-notification-checkbox'
          end

          view 'app/assets/javascripts/alerts_settings/components/alerts_settings_form.vue' do
            element 'integration-type-dropdown'
            element 'integration-name-field'
            element 'active-toggle-container'
            element 'save-and-create-alert-button'
            element 'test-payload-field'
            element 'send-test-alert'
          end

          def go_to_alert_settings
            click_link_with_text('Alert settings')
          end

          def enable_incident_for_alert
            check_element('create-incident-checkbox', true)
          end

          def enable_email_notification
            check_element('enable-email-notification-checkbox', true)
          end

          def select_issue_template(template)
            click_element('incident-templates-dropdown')
            within_element 'incident-templates-dropdown' do
              select_item(template)
            end
          end

          def save_alert_settings
            click_element 'save-changes-button'
          end

          def has_template?(template)
            within_element 'incident-templates-dropdown' do
              has_text?(template)
            end
          end

          def add_new_integration
            wait_for_requests
            click_element('crud-form-toggle')
          end

          def select_http_endpoint
            click_element('integration-type-dropdown')
            find("option[value='HTTP']").click

            # Click outside of the list to close it
            click_element('integration-name-field')
          end

          def select_prometheus
            click_element('integration-type-dropdown')
            find("option[value='PROMETHEUS']").click
          end

          def enter_integration_name(name)
            fill_element('integration-name-field', name)
          end

          def activate_integration
            within_element('active-toggle-container') do
              find('.gl-toggle').click
            end

            wait_for_requests
          end

          def save_and_create_alert
            click_element('save-and-create-alert-button')
          end

          def fill_in_test_payload(payload)
            fill_element('test-payload-field', payload)
          end

          def send_test_alert
            click_element('send-test-alert')
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

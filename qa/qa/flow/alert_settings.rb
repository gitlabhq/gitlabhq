# frozen_string_literal: true

module QA
  module Flow
    module AlertSettings
      extend self

      def go_to_monitor_settings
        Page::Project::Menu.perform(&:go_to_monitor_settings)
      end

      def setup_http_endpoint_integration(integration_name: random_word)
        Page::Project::Settings::Monitor.perform do |setting|
          setting.expand_alerts do |alert|
            alert.add_new_integration
            alert.select_http_endpoint
            alert.enter_integration_name(integration_name)
            alert.activate_integration
            alert.save_and_create_alert
          end
        end
      end

      def setup_prometheus_integration
        Page::Project::Settings::Monitor.perform do |setting|
          setting.expand_alerts do |alert|
            alert.add_new_integration
            alert.select_prometheus
            alert.activate_integration
            alert.fill_in_prometheus_url
            alert.save_and_create_alert
          end
        end
      end

      def send_test_alert(payload: { title: random_word, description: random_word })
        Page::Project::Settings::Alerts.perform do |alert|
          alert.fill_in_test_payload(payload.to_json)
          alert.send_test_alert
        end
      end

      def integration_credentials
        credentials = {}
        Page::Project::Settings::Alerts.perform do |alert|
          alert.go_to_view_credentials
          credentials = { url: alert.webhook_url, auth_key: alert.authorization_key }
        end

        credentials
      end

      def enable_create_incident
        Page::Project::Settings::Monitor.perform do |setting|
          setting.expand_alerts do |alert|
            alert.go_to_alert_settings
            alert.enable_incident_for_alert
            alert.save_alert_settings
            alert.click_button('Collapse')
          end
        end
      end

      private

      def random_word
        Faker::Lorem.word
      end
    end
  end
end

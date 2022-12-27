# frozen_string_literal: true

module QA
  module Flow
    module AlertSettings
      extend self

      def setup_http_endpoint_and_send_alert(integration_name: nil, payload: nil)
        integration_name ||= random_word
        payload ||= { title: random_word, description: random_word }
        Page::Project::Menu.perform(&:go_to_monitor_settings)
        Page::Project::Settings::Monitor.perform do |setting|
          setting.expand_alerts do |alert|
            alert.add_new_integration
            alert.select_http_endpoint
            alert.enter_integration_name(integration_name)
            alert.activate_integration
            alert.save_and_create_alert
            alert.fill_in_test_payload(payload.to_json)
            alert.send_test_alert
          end
        end
      end

      def setup_prometheus_and_send_alert(payload: nil)
        payload ||= { title: random_word, description: random_word }
        Page::Project::Menu.perform(&:go_to_monitor_settings)
        Page::Project::Settings::Monitor.perform do |setting|
          setting.expand_alerts do |alert|
            alert.add_new_integration
            alert.select_prometheus
            alert.activate_integration
            alert.fill_in_prometheus_url
            alert.save_and_create_alert
            alert.fill_in_test_payload(payload.to_json)
            alert.send_test_alert
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

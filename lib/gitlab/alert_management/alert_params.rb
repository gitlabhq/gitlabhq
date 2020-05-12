# frozen_string_literal: true

module Gitlab
  module AlertManagement
    class AlertParams
      MONITORING_TOOLS = {
        prometheus: 'Prometheus'
      }.freeze

      def self.from_generic_alert(project:, payload:)
        parsed_payload = Gitlab::Alerting::NotificationPayloadParser.call(payload).with_indifferent_access
        annotations = parsed_payload[:annotations]

        {
          project_id: project.id,
          title: annotations[:title],
          description: annotations[:description],
          monitoring_tool: annotations[:monitoring_tool],
          service: annotations[:service],
          hosts: Array(annotations[:hosts]),
          payload: payload,
          started_at: parsed_payload['startsAt']
        }
      end

      def self.from_prometheus_alert(project:, parsed_alert:)
        {
          project_id: project.id,
          title: parsed_alert.title,
          description: parsed_alert.description,
          monitoring_tool: MONITORING_TOOLS[:prometheus],
          payload: parsed_alert.payload,
          started_at: parsed_alert.starts_at,
          ended_at: parsed_alert.ends_at,
          fingerprint: parsed_alert.gitlab_fingerprint
        }
      end
    end
  end
end

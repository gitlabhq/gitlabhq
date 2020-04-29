# frozen_string_literal: true

module Gitlab
  module AlertManagement
    class AlertParams
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
    end
  end
end

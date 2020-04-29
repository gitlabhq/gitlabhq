# frozen_string_literal: true

module Projects
  module Alerting
    class NotifyService < BaseService
      include Gitlab::Utils::StrongMemoize
      include IncidentManagement::Settings

      def execute(token)
        return forbidden unless alerts_service_activated?
        return unauthorized unless valid_token?(token)

        alert = create_alert
        return bad_request unless alert.persisted?

        process_incident_issues(alert) if process_issues?
        send_alert_email if send_email?

        ServiceResponse.success
      rescue Gitlab::Alerting::NotificationPayloadParser::BadPayloadError
        bad_request
      end

      private

      delegate :alerts_service, :alerts_service_activated?, to: :project

      def am_alert_params
        Gitlab::AlertManagement::AlertParams.from_generic_alert(project: project, payload: params.to_h)
      end

      def create_alert
        AlertManagement::Alert.create(am_alert_params)
      end

      def send_email?
        incident_management_setting.send_email?
      end

      def process_incident_issues(alert)
        IncidentManagement::ProcessAlertWorker
          .perform_async(project.id, parsed_payload, alert.id)
      end

      def send_alert_email
        notification_service
          .async
          .prometheus_alerts_fired(project, [parsed_payload])
      end

      def parsed_payload
        Gitlab::Alerting::NotificationPayloadParser.call(params.to_h)
      end

      def valid_token?(token)
        token == alerts_service.token
      end

      def bad_request
        ServiceResponse.error(message: 'Bad Request', http_status: :bad_request)
      end

      def unauthorized
        ServiceResponse.error(message: 'Unauthorized', http_status: :unauthorized)
      end

      def forbidden
        ServiceResponse.error(message: 'Forbidden', http_status: :forbidden)
      end
    end
  end
end

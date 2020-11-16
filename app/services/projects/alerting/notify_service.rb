# frozen_string_literal: true

module Projects
  module Alerting
    class NotifyService < BaseService
      include Gitlab::Utils::StrongMemoize
      include ::IncidentManagement::Settings

      def execute(token, integration = nil)
        @integration = integration

        return bad_request unless valid_payload_size?
        return forbidden unless active_integration?
        return unauthorized unless valid_token?(token)

        process_alert
        return bad_request unless alert.persisted?

        process_incident_issues if process_issues?
        send_alert_email if send_email?

        ServiceResponse.success
      end

      private

      attr_reader :integration

      def process_alert
        if alert.persisted?
          process_existing_alert
        else
          create_alert
        end
      end

      def process_existing_alert
        if incoming_payload.ends_at.present?
          process_resolved_alert
        else
          alert.register_new_event!
        end

        alert
      end

      def process_resolved_alert
        return unless auto_close_incident?

        if alert.resolve(incoming_payload.ends_at)
          close_issue(alert.issue)
        end

        alert
      end

      def close_issue(issue)
        return if issue.blank? || issue.closed?

        ::Issues::CloseService
          .new(project, User.alert_bot)
          .execute(issue, system_note: false)

        SystemNoteService.auto_resolve_prometheus_alert(issue, project, User.alert_bot) if issue.reset.closed?
      end

      def create_alert
        return unless alert.save

        alert.execute_services
        SystemNoteService.create_new_alert(alert, notification_source)
      end

      def process_incident_issues
        return if alert.issue || alert.resolved?

        ::IncidentManagement::ProcessAlertWorker.perform_async(nil, nil, alert.id)
      end

      def send_alert_email
        notification_service
          .async
          .prometheus_alerts_fired(project, [alert])
      end

      def alert
        strong_memoize(:alert) do
          existing_alert || new_alert
        end
      end

      def existing_alert
        return unless incoming_payload.gitlab_fingerprint

        AlertManagement::Alert.not_resolved.for_fingerprint(project, incoming_payload.gitlab_fingerprint).first
      end

      def new_alert
        AlertManagement::Alert.new(**incoming_payload.alert_params, ended_at: nil)
      end

      def incoming_payload
        strong_memoize(:incoming_payload) do
          Gitlab::AlertManagement::Payload.parse(project, params.to_h)
        end
      end

      def notification_source
        alert.monitoring_tool || integration&.name || 'Generic Alert Endpoint'
      end

      def valid_payload_size?
        Gitlab::Utils::DeepSize.new(params).valid?
      end

      def active_integration?
        integration&.active?
      end

      def valid_token?(token)
        token == integration.token
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

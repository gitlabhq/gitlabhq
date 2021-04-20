# frozen_string_literal: true

module Projects
  module Alerting
    class NotifyService
      extend ::Gitlab::Utils::Override
      include ::AlertManagement::AlertProcessing

      def initialize(project, payload)
        @project = project
        @payload = payload
      end

      def execute(token, integration = nil)
        @integration = integration

        return bad_request unless valid_payload_size?
        return forbidden unless active_integration?
        return unauthorized unless valid_token?(token)

        process_alert
        return bad_request unless alert.persisted?

        complete_post_processing_tasks

        ServiceResponse.success
      end

      private

      attr_reader :project, :payload, :integration

      def valid_payload_size?
        Gitlab::Utils::DeepSize.new(payload).valid?
      end

      override :alert_source
      def alert_source
        super || integration&.name || 'Generic Alert Endpoint'
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

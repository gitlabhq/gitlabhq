# frozen_string_literal: true

module IncidentManagement
  module PagerDuty
    class ProcessWebhookService < ::BaseProjectService
      include Gitlab::Utils::StrongMemoize
      include IncidentManagement::Settings

      # https://developer.pagerduty.com/docs/webhooks/webhook-behavior/#size-limit
      PAGER_DUTY_PAYLOAD_SIZE_LIMIT = 55.kilobytes

      # https://developer.pagerduty.com/docs/db0fa8c8984fc-overview#event-types
      PAGER_DUTY_PROCESSABLE_EVENT_TYPES = %w[incident.triggered].freeze

      def initialize(project, payload)
        super(project: project)

        @payload = payload
      end

      def execute(token)
        return forbidden unless webhook_setting_active?
        return unauthorized unless valid_token?(token)
        return bad_request unless valid_payload_size?

        process_incidents

        accepted
      end

      private

      attr_reader :payload

      def process_incidents
        event = pager_duty_processable_event
        return unless event

        ::IncidentManagement::PagerDuty::ProcessIncidentWorker
          .perform_async(project.id, event['incident'])
      end

      def pager_duty_processable_event
        strong_memoize(:pager_duty_processable_event) do
          event = ::PagerDuty::WebhookPayloadParser.call(payload.to_h)

          event if event['event'].to_s.in?(PAGER_DUTY_PROCESSABLE_EVENT_TYPES)
        end
      end

      def webhook_setting_active?
        incident_management_setting.pagerduty_active?
      end

      def valid_token?(token)
        token && incident_management_setting.pagerduty_token == token
      end

      def valid_payload_size?
        Gitlab::Utils::DeepSize.new(payload, max_size: PAGER_DUTY_PAYLOAD_SIZE_LIMIT).valid?
      end

      def accepted
        ServiceResponse.success(http_status: :accepted)
      end

      def forbidden
        ServiceResponse.error(message: 'Forbidden', http_status: :forbidden)
      end

      def unauthorized
        ServiceResponse.error(message: 'Unauthorized', http_status: :unauthorized)
      end

      def bad_request
        ServiceResponse.error(message: 'Bad Request', http_status: :bad_request)
      end
    end
  end
end

# frozen_string_literal: true

module Integrations
  module SlackInteractions
    class ViewSubmissionService
      HANDLERS = {
        'incident_modal' => SlackInteractions::IncidentManagement::IncidentModalSubmitService
      }.freeze

      def initialize(params)
        @params = params
      end

      def execute
        handler_class = handlers[callback_id]

        unless handler_class
          Gitlab::IntegrationsLogger.warn(
            message: 'Ignoring Slack view_submission with unknown callback_id',
            callback_id: callback_id
          )
          return ServiceResponse.success
        end

        handler_class.new(params).execute
      end

      private

      attr_reader :params

      def callback_id
        params.dig(:view, :callback_id)
      end

      def handlers
        HANDLERS
      end
    end
  end
end

Integrations::SlackInteractions::ViewSubmissionService.prepend_mod

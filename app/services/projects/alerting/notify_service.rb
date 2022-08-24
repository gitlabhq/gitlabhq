# frozen_string_literal: true

module Projects
  module Alerting
    class NotifyService < ::BaseProjectService
      extend ::Gitlab::Utils::Override
      include ::AlertManagement::AlertProcessing
      include ::AlertManagement::Responses

      def initialize(project, params)
        super(project: project, params: params.to_h)
      end

      def execute(token, integration = nil)
        @integration = integration

        return bad_request unless valid_payload_size?
        return forbidden unless active_integration?
        return unauthorized unless valid_token?(token)

        process_alert
        return bad_request unless alert.persisted?

        complete_post_processing_tasks

        success(alert)
      end

      private

      attr_reader :integration
      alias_method :payload, :params

      def valid_payload_size?
        Gitlab::Utils::DeepSize.new(params).valid?
      end

      def active_integration?
        integration&.active?
      end

      def valid_token?(token)
        token == integration.token
      end
    end
  end
end

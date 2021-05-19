# frozen_string_literal: true

module AlertManagement
  class ProcessPrometheusAlertService
    extend ::Gitlab::Utils::Override
    include ::AlertManagement::AlertProcessing

    def initialize(project, payload)
      @project = project
      @payload = payload
    end

    def execute
      return bad_request unless incoming_payload.has_required_attributes?

      process_alert
      return bad_request unless alert.persisted?

      complete_post_processing_tasks

      ServiceResponse.success
    end

    private

    attr_reader :project, :payload

    override :incoming_payload
    def incoming_payload
      strong_memoize(:incoming_payload) do
        Gitlab::AlertManagement::Payload.parse(
          project,
          payload,
          monitoring_tool: Gitlab::AlertManagement::Payload::MONITORING_TOOLS[:prometheus]
        )
      end
    end

    override :resolving_alert?
    def resolving_alert?
      incoming_payload.resolved?
    end

    def bad_request
      ServiceResponse.error(message: 'Bad Request', http_status: :bad_request)
    end
  end
end

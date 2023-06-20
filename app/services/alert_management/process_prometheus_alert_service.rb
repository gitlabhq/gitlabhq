# frozen_string_literal: true

module AlertManagement
  class ProcessPrometheusAlertService
    extend ::Gitlab::Utils::Override
    include ::AlertManagement::AlertProcessing
    include ::AlertManagement::Responses

    def initialize(project, payload, integration: nil)
      @project = project
      @payload = payload
      @integration = integration
    end

    def execute
      return bad_request unless incoming_payload.has_required_attributes?

      process_alert
      return bad_request unless alert.persisted?

      complete_post_processing_tasks

      success(alert)
    end

    private

    attr_reader :project, :payload, :integration

    override :incoming_payload
    def incoming_payload
      strong_memoize(:incoming_payload) do
        Gitlab::AlertManagement::Payload.parse(
          project,
          payload,
          integration: integration,
          monitoring_tool: Gitlab::AlertManagement::Payload::MONITORING_TOOLS[:prometheus]
        )
      end
    end
  end
end

module Ci
  class SendPipelineNotificationService
    attr_reader :pipeline

    def initialize(new_pipeline)
      @pipeline = new_pipeline
    end

    def execute(recipients = nil)
      notification_service.pipeline_finished(pipeline, recipients)
    end
  end
end

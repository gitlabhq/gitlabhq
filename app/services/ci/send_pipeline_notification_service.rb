module Ci
  class SendPipelineNotificationService
    attr_reader :pipeline

    def initialize(new_pipeline)
      @pipeline = new_pipeline
    end

    def execute(recipients)
      email_template = "pipeline_#{pipeline.status}_email"

      return unless Notify.respond_to?(email_template)

      recipients.each do |to|
        Notify.public_send(email_template, pipeline, to).deliver_later
      end
    end
  end
end

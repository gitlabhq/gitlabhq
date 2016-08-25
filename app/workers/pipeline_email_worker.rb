class PipelineEmailWorker
  include Sidekiq::Worker

  ParamsStruct = Struct.new(:pipeline, :project, :email_template)
  class Params < ParamsStruct
    def initialize(pipeline_id)
      self.pipeline = Ci::Pipeline.find(pipeline_id)
      self.project = pipeline.project
      self.email_template = case pipeline.status
                            when 'success'
                              :pipeline_succeeded_email
                            when 'failed'
                              :pipeline_failed_email
                            end
    end
  end

  def perform(data, recipients)
    params = Params.new(data['object_attributes']['id'])

    return unless params.email_template

    recipients.each do |to|
      deliver(params, to) do
        Notify.public_send(params.email_template, params, to).deliver_now
      end
    end
  end

  private

  def deliver(params, to)
    yield
  # These are input errors and won't be corrected even if Sidekiq retries
  rescue Net::SMTPFatalError, Net::SMTPSyntaxError => e
    project_name = params.project.path_with_namespace
    logger.info("Failed to send email for #{project_name} to #{to}: #{e}")
  end
end

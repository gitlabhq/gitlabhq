class SendPipelineNotificationWorker
  include Sidekiq::Worker

  def perform(pipeline_id, recipients = nil)
    pipeline = Ci::Pipeline.find(pipeline_id)

    NotificationService.new.pipeline_finished(pipeline, recipients)
  end
end

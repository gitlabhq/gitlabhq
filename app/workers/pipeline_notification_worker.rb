class PipelineNotificationWorker
  include Sidekiq::Worker

  def perform(pipeline_id, recipients = nil)
    pipeline = Ci::Pipeline.find_by(id: pipeline_id)

    return unless pipeline

    NotificationService.new.pipeline_finished(pipeline, recipients)
  end
end

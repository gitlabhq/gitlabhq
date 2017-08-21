class PipelineNotificationWorker
  include Sidekiq::Worker
  include PipelineQueue

  enqueue_in group: :hooks

  def perform(pipeline_id, recipients = nil)
    pipeline = Ci::Pipeline.find_by(id: pipeline_id)

    return unless pipeline

    NotificationService.new.pipeline_finished(pipeline, recipients)
  end
end

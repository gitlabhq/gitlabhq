# frozen_string_literal: true

class PipelineNotificationWorker
  include ApplicationWorker
  include PipelineQueue

  # rubocop: disable CodeReuse/ActiveRecord
  def perform(pipeline_id, recipients = nil)
    pipeline = Ci::Pipeline.find_by(id: pipeline_id)

    return unless pipeline

    NotificationService.new.pipeline_finished(pipeline, recipients)
  end
  # rubocop: enable CodeReuse/ActiveRecord
end

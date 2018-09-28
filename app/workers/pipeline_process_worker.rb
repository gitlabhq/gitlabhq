# frozen_string_literal: true

class PipelineProcessWorker
  include ApplicationWorker
  include PipelineQueue

  queue_namespace :pipeline_processing

  # rubocop: disable CodeReuse/ActiveRecord
  def perform(pipeline_id)
    Ci::Pipeline.find_by(id: pipeline_id)
      .try(:process!)
  end
  # rubocop: enable CodeReuse/ActiveRecord
end

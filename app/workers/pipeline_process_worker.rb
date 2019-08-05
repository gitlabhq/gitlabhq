# frozen_string_literal: true

class PipelineProcessWorker
  include ApplicationWorker
  include PipelineQueue

  queue_namespace :pipeline_processing

  # rubocop: disable CodeReuse/ActiveRecord
  def perform(pipeline_id, build_ids = nil)
    Ci::Pipeline.find_by(id: pipeline_id).try do |pipeline|
      pipeline.process!(build_ids)
    end
  end
  # rubocop: enable CodeReuse/ActiveRecord
end

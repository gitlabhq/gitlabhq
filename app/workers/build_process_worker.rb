# frozen_string_literal: true

class BuildProcessWorker
  include ApplicationWorker
  include PipelineQueue

  queue_namespace :pipeline_processing

  # rubocop: disable CodeReuse/ActiveRecord
  def perform(build_id)
    CommitStatus.find_by(id: build_id).try do |build|
      build.pipeline.process!(build.name)
    end
  end
  # rubocop: enable CodeReuse/ActiveRecord
end

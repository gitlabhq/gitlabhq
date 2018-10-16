# frozen_string_literal: true

class DeploymentUpdateWorker
  include ApplicationWorker
  include PipelineQueue

  queue_namespace :pipeline_processing

  # rubocop: disable CodeReuse/ActiveRecord
  def perform(job_id)
    Deployment.find_by(deployable_id: job_id).try do |deployment|
      deployment.update_status
    end
  end
  # rubocop: enable CodeReuse/ActiveRecord
end

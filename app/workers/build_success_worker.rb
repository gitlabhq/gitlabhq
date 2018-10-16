# frozen_string_literal: true

class BuildSuccessWorker
  include ApplicationWorker
  include PipelineQueue

  queue_namespace :pipeline_processing

  # rubocop: disable CodeReuse/ActiveRecord
  def perform(build_id)
    Ci::Build.find_by(id: build_id).try do |build|
      update_deployment_metrics(build) if build.has_environment?
    end
  end
  # rubocop: enable CodeReuse/ActiveRecord

  private

  def update_deployment_metrics(build)
    UpdateDeploymentMetricsService.new(build).execute
  end
end

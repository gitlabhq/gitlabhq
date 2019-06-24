# frozen_string_literal: true

class BuildSuccessWorker
  include ApplicationWorker
  include PipelineQueue

  queue_namespace :pipeline_processing

  # rubocop: disable CodeReuse/ActiveRecord
  def perform(build_id)
    Ci::Build.find_by(id: build_id).try do |build|
      stop_environment(build) if build.stops_environment?
    end
  end
  # rubocop: enable CodeReuse/ActiveRecord

  private

  ##
  # TODO: This should be processed in DeploymentSuccessWorker once we started storing `action` value in `deployments` records
  def stop_environment(build)
    build.persisted_environment.fire_state_event(:stop)
  end
end

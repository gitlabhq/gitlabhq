# frozen_string_literal: true

class BuildSuccessWorker
  include ApplicationWorker
  include PipelineQueue

  queue_namespace :pipeline_processing

  # rubocop: disable CodeReuse/ActiveRecord
  def perform(build_id)
    Ci::Build.find_by(id: build_id).try do |build|
      create_deployment(build) if build.has_environment?
      stop_environment(build) if build.stops_environment?
    end
  end
  # rubocop: enable CodeReuse/ActiveRecord

  private

  ##
  # Deprecated:
  # As of 11.5, we started creating a deployment record when ci_builds record is created.
  # Therefore we no longer need to create a deployment, after a build succeeded.
  # We're leaving this code for the transition period, but we can remove this code in 11.6.
  def create_deployment(build)
    build.create_deployment.try do |deployment|
      deployment.succeed
    end
  end

  ##
  # TODO: This should be processed in DeploymentSuccessWorker once we started storing `action` value in `deployments` records
  def stop_environment(build)
    build.persisted_environment.fire_state_event(:stop)
  end
end

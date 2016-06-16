require_relative 'base_service'

class CreateDeploymentService < BaseService
  def execute(deployable = nil)
    environment = project.environments.find_or_create_by(
      name: params[:environment]
    )

    project.deployments.create(
      environment: environment,
      ref: params[:ref],
      tag: params[:tag],
      sha: params[:sha],
      user: current_user,
      deployable: deployable
    )
  end
end

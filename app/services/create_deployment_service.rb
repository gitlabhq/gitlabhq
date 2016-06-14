require_relative 'base_service'

class CreateDeploymentService < BaseService
  def execute(deployable = nil)
    environment = create_or_find_environment(params[:environment])

    project.deployments.create(
      environment: environment,
      ref: params[:ref],
      tag: params[:tag],
      sha: params[:sha],
      user: current_user,
      deployable: deployable,
    )
  end

  private

  def create_or_find_environment(environment)
    find_environment(environment) || create_environment(environment)
  end

  def create_environment(environment)
    project.environments.create(name: environment)
  end

  def find_environment(environment)
    project.environments.find_by(name: environment)
  end
end

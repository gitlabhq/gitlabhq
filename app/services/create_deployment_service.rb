require_relative 'base_service'

class CreateDeploymentService < BaseService
  def execute(deployable)
    environment = find_environment(params[:environment])
    return error('no environment') unless environmnet

    deployment = create_deployment(environment, deployable)
    if deployment.persisted?
      success(deployment)
    else
      error(deployment.errors)
    end
  end

  private

  def find_environment(environment)
    project.environments.find_by(name: environment)
  end

  def create_deployment(environment, deployable)
    environment.deployments.create(
      project: project,
      ref: build.ref,
      tag: build.tag,
      sha: build.sha,
      user: current_user,
      deployable: deployable,
    )
  end

  def success(deployment)
    out = super()
    out[:deployment] = deployment
    out
  end
end

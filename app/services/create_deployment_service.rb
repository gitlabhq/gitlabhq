require_relative 'base_service'

class CreateDeploymentService < BaseService
  def execute(deployable = nil)
    environment = project.environments.find_or_create_by(
      name: expanded_name
    )

    if expanded_url
      environment.external_url = expanded_url
    end

    project.deployments.create(
      environment: environment,
      ref: params[:ref],
      tag: params[:tag],
      sha: params[:sha],
      user: current_user,
      deployable: deployable
    )
  end

  private

  def expanded_name
    name.expand_variables(variables)
  end

  def expanded_url
    return unless url

    @expanded_url ||= url.expand_variables(variables)
  end

  def name
    params[:environment]
  end

  def url
    options[:url]
  end

  def options
    params[:environment] || {}
  end

  def variables
    params[:variables] || []
  end
end

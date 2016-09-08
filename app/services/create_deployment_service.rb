require_relative 'base_service'

class CreateDeploymentService < BaseService
  def execute(deployable = nil)
    environment = find_or_create_environment

    deployment = project.deployments.create(
                  environment: environment,
                  ref: params[:ref],
                  tag: params[:tag],
                  sha: params[:sha],
                  user: current_user,
                  deployable: deployable
                )
    deployment.create_refs

    deployment
  end

  private

  def find_or_create_environment
    project.environments.find_or_create_by(name: expanded_name) do |environment|
      environment.external_url = expanded_url
    end
  end

  def expanded_name
    ExpandVariables.expand(name, variables)
  end

  def expanded_url
    return unless url

    @expanded_url ||= ExpandVariables.expand(url, variables)
  end

  def name
    params[:environment]
  end

  def url
    options[:url]
  end

  def options
    params[:options] || {}
  end

  def variables
    params[:variables] || []
  end
end

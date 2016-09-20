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

    update_merge_request_metrics(deployment, environment)

    deployment
  end

  private

  def update_merge_request_metrics(deployment, environment)
    if environment.name == "production"
      query = project.merge_requests.joins("LEFT OUTER JOIN merge_request_metrics ON merge_request_metrics.merge_request_id = merge_requests.id").
              where(target_branch: params[:ref], "merge_request_metrics.first_deployed_to_production_at" => nil)

      previous_deployment = previous_deployment_for_ref(deployment)
      merge_requests_deployed_to_production_for_first_time = if previous_deployment
                                                               query.where("merge_request_metrics.merged_at < ? AND merge_request_metrics.merged_at > ?", deployment.created_at, previous_deployment.created_at)
                                                             else
                                                               query.where("merge_request_metrics.merged_at < ?", deployment.created_at)
                                                             end

      merge_requests_deployed_to_production_for_first_time.each { |merge_request| merge_request.metrics.record_production_deploy!(deployment.created_at) }
    end
  end

  def previous_deployment_for_ref(current_deployment)
    @previous_deployment_for_ref ||=
      project.deployments.joins(:environment).
      where("environments.name": params[:environment], ref: params[:ref]).
      where.not(id: current_deployment.id).
      first
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

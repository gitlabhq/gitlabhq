require_relative 'base_service'

class CreateDeploymentService < BaseService
  def execute(deployable = nil)
    environment = project.environments.find_or_create_by(
      name: params[:environment]
    )

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
    # TODO: Test cases:
    # 1. Merge request with metrics available and `first_deployed_to_production_at` is nil
    # 2. Merge request with metrics available and `first_deployed_to_production_at` is set
    # 3. Merge request with metrics unavailable
    # 4. Only applies to merge requests merged AFTER the previous production deploy to this branch
    if environment.name == "production"
      merge_requests_deployed_to_production_for_first_time = project.merge_requests.joins("LEFT OUTER JOIN merge_request_metrics ON merge_request_metrics.merge_request_id = merge_requests.id").
                                                             where(target_branch: params[:ref], "merge_request_metrics.first_deployed_to_production_at" => nil).
                                                             where("merge_request_metrics.merged_at < ?", deployment.created_at)

      merge_requests_deployed_to_production_for_first_time.each { |merge_request| merge_request.metrics.record_production_deploy!(deployment.created_at) }
    end
  end
end

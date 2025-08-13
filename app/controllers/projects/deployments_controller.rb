# frozen_string_literal: true

class Projects::DeploymentsController < Projects::ApplicationController
  before_action :authorize_read_deployment!
  before_action :environment

  feature_category :continuous_delivery
  urgency :low

  # rubocop: disable CodeReuse/ActiveRecord
  def index
    deployments = environment.deployments.reorder(created_at: :desc)
    deployments = deployments.where('created_at > ?', params[:after].to_time) if params[:after]&.to_time

    render json: { deployments: DeploymentSerializer.new(project: project)
                                  .represent_concise(deployments) }
  end
  # rubocop: enable CodeReuse/ActiveRecord

  def show
    # A deployment belongs to both a project and an environment so either
    # association could be used to fetch this record. However, because the
    # IID is defined at the project level, looking up via project is a more
    # efficient query as it can use the unique index on (project_id, iid).
    @deployment = project.deployments.find_by_iid!(params[:id])
  end

  private

  def environment
    @environment ||= project.environments.find(params[:environment_id])
  end
end

# frozen_string_literal: true

class Projects::DeploymentsController < Projects::ApplicationController
  before_action :authorize_read_deployment!

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
    @deployment = environment.all_deployments.find_by_iid!(params[:id])
  end

  private

  def deployment
    @deployment ||= environment.deployments.find_successful_deployment!(params[:id])
  end

  def environment
    @environment ||= project.environments.find(params[:environment_id])
  end
end

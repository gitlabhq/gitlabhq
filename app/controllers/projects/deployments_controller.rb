class Projects::DeploymentsController < Projects::ApplicationController
  before_action :authorize_read_deployment!

  def index
    serializer = DeploymentSerializer.new(user: @current_user, project: project)

    deployments = environment.deployments.reorder(created_at: :desc)
    deployments = deployments.where('created_at > ?', params[:after].to_time) if params[:after]&.to_time
    deployments = deployments.map { |deployment| serializer.represent(deployment) }

    render json: { deployments: deployments }
  end

  private

  def environment
    @environment ||= project.environments.find(params[:environment_id])
  end
end

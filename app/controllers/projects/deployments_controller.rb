class Projects::DeploymentsController < Projects::ApplicationController
  before_action :authorize_read_environment!
  before_action :authorize_read_deployment!

  def index
    deployments = environment.deployments.reorder(created_at: :desc)
    deployments = deployments.where('created_at > ?', params[:after].to_time) if params[:after]&.to_time

    render json: { deployments: DeploymentSerializer.new(user: @current_user, project: project)
                                  .represent_concise(deployments) }
  end

  private

  def environment
    @environment ||= project.environments.find(params[:environment_id])
  end
end

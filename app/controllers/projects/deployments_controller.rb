class Projects::DeploymentsController < Projects::ApplicationController
  before_action :authorize_read_deployment!

  def index
    serializer = DeploymentSerializer.new(user: @current_user)
    deployments = environment.deployments.where('created_at > ?', 8.hours.ago)
                    .map { |d| serializer.represent(d) }

    render json: { deployments: deployments }
  end

  private

  def environment
    @environment ||= project.environments.find(params[:environment_id])
  end
end

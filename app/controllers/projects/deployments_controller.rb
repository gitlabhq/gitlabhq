class Projects::DeploymentsController < Projects::ApplicationController
  before_action :authorize_read_deployment!

  def metrics
    @metrics = deployment.metrics(1.hour)

    if @metrics&.any?
      render json: @metrics, status: :ok
    else
      head :no_content
    end
  end

  private

  def deployment
    @deployment ||= environment.deployments.find_by(iid: params[:id])
  end

  def environment
    @environment ||= project.environments.find(params[:environment_id])
  end
end

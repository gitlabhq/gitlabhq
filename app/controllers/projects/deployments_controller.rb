class Projects::DeploymentsController < Projects::ApplicationController
  before_action :authorize_read_deployment!

  def index
    deployments = environment.deployments.where('created_at > ?', 8.hours.ago)
                    .map { |d| d.slice(:id, :iid, :created_at, :sha, :ref, :tag) }

    render json: { deployments: deployments }
  end

  private

  def environment
    @environment ||= project.environments.find(params[:environment_id])
  end
end

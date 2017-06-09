class Projects::DeploymentsController < Projects::ApplicationController
  before_action :authorize_read_environment!
  before_action :authorize_read_deployment!

  def index
    deployments = environment.deployments.reorder(created_at: :desc)
    deployments = deployments.where('created_at > ?', params[:after].to_time) if params[:after]&.to_time

    render json: { deployments: DeploymentSerializer.new(project: project)
                                  .represent_concise(deployments) }
  end

  def metrics
<<<<<<< HEAD
    @metrics = deployment.metrics(1.hour)

=======
    return render_404 unless deployment.has_metrics?
    @metrics = deployment.metrics
>>>>>>> abc61f260074663e5711d3814d9b7d301d07a259
    if @metrics&.any?
      render json: @metrics, status: :ok
    else
      head :no_content
    end
<<<<<<< HEAD
=======
  rescue NotImplementedError
    render_404
>>>>>>> abc61f260074663e5711d3814d9b7d301d07a259
  end

  private

  def deployment
    @deployment ||= environment.deployments.find_by(iid: params[:id])
  end

  def environment
    @environment ||= project.environments.find(params[:environment_id])
  end
end

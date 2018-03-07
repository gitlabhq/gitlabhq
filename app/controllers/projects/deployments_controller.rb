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
    return render_404 unless deployment.has_metrics?

    @metrics = deployment.metrics
    if @metrics&.any?
      render json: @metrics, status: :ok
    else
      head :no_content
    end
  rescue NotImplementedError
    render_404
  end

  def additional_metrics
    return render_404 unless deployment.has_metrics?

    respond_to do |format|
      format.json do
        metrics = deployment.additional_metrics

        if metrics.any?
          render json: metrics
        else
          head :no_content
        end
      end
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

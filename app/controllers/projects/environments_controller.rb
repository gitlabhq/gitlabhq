class Projects::EnvironmentsController < Projects::ApplicationController
  layout 'project'
  before_action :authorize_read_environment!
  before_action :environment, only: [:show, :destroy]

  def index
    @environments = project.environments
  end

  def show
    @deployments = environment.deployments.order(id: :desc).page(params[:page]).per(30)
  end

  def new
    @environment = project.environments.new
  end

  def create
    @environment = project.environments.create(create_params)
    unless @environment.persisted?
      render 'new'
      return
    end

    redirect_to namespace_project_environment_path(project.namespace, project, @environment)
  end

  def destroy
    if @environment.destroy
      redirect_to namespace_project_environments_path(project.namespace, project), notice: 'Environment was successfully removed.'
    else
      redirect_to namespace_project_environments_path(project.namespace, project), alert: 'Failed to remove environment.'
    end
  end

  private

  def create_params
    params.require(:environment).permit(:name)
  end

  def environment
    @environment ||= project.environments.find(params[:id].to_s)
    @environment || render_404
  end
end

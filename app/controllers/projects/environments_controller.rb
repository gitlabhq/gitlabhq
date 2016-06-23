class Projects::EnvironmentsController < Projects::ApplicationController
  layout 'project'
  before_action :authorize_read_environment!
  before_action :authorize_create_environment!, only: [:new, :create]
  before_action :authorize_update_environment!, only: [:destroy]
  before_action :environment, only: [:show, :destroy]

  def index
    @environments = project.environments
  end

  def show
    @deployments = environment.deployments.order(id: :desc).page(params[:page])
  end

  def new
    @environment = project.environments.new
  end

  def create
    @environment = project.environments.create(create_params)

    if @environment.persisted?
      redirect_to namespace_project_environment_path(project.namespace, project, @environment)
    else
      render 'new'
    end
  end

  def destroy
    if @environment.destroy
      flash[:notice] = 'Environment was successfully removed.'
    else
      flash[:alert] = 'Failed to remove environment.'
    end

    redirect_to namespace_project_environments_path(project.namespace, project)
  end

  private

  def create_params
    params.require(:environment).permit(:name)
  end

  def environment
    @environment ||= project.environments.find(params[:id])
  end
end

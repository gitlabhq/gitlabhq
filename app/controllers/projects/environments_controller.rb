class Projects::EnvironmentsController < Projects::ApplicationController
  layout 'project'
  before_action :authorize_read_environment!
  before_action :authorize_create_environment!, only: [:new, :create]
  before_action :authorize_update_environment!, only: [:edit, :update, :destroy]
  before_action :environment, only: [:show, :edit, :update, :destroy]

  def index
    @scope = params[:scope]
    @environments = project.environments
    
    # TODO: fix the values of this vars to show the correct results
    @available_environments_count = project.environments.count
    @stopped_environments_count = project.environments.count
  end

  def show
    @deployments = environment.deployments.order(id: :desc).page(params[:page])
  end

  def new
    @environment = project.environments.new
  end

  def edit
  end

  def create
    @environment = project.environments.create(environment_params)

    if @environment.persisted?
      redirect_to namespace_project_environment_path(project.namespace, project, @environment)
    else
      render :new
    end
  end

  def update
    if @environment.update(environment_params)
      redirect_to namespace_project_environment_path(project.namespace, project, @environment)
    else
      render :edit
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

  def environment_params
    params.require(:environment).permit(:name, :external_url)
  end

  def environment
    @environment ||= project.environments.find(params[:id])
  end
end

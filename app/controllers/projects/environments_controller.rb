class Projects::EnvironmentsController < Projects::ApplicationController
  layout 'project'
  before_action :authorize_read_environment!
  before_action :authorize_create_environment!, only: [:new, :create]
  before_action :authorize_update_environment!, only: [:edit, :update, :close, :destroy]
  before_action :environment, only: [:show, :edit, :update, :destroy]

  def index
    @scope = params[:scope]
    @all_environments = project.environments
    @environments =
      case @scope
        when 'closed' then @all_environments.closed
        else @all_environments.opened
      end
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

  def close
    close_action = @environment.close_action
    if close_action
      close_build = close_action.play(current_user)
      redirect_to namespace_project_build_path(project.namespace, project, close_build)
    else
      @environment.close
      redirect_to namespace_project_environment_path(project.namespace, project, @environment)
    end
  end

  private

  def environment_params
    params.require(:environment).permit(:name, :external_url)
  end

  def environment
    @environment ||= project.environments.find(params[:id])
  end
end

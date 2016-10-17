class Projects::EnvironmentsController < Projects::ApplicationController
  layout 'project'
  before_action :authorize_read_environment!
  before_action :authorize_create_environment!, only: [:new, :create]
  before_action :authorize_update_environment!, only: [:edit, :update, :stop]
  before_action :environment, only: [:show, :edit, :update, :stop]

  def index
    @scope = params[:scope]
    @all_environments = project.environments
    @environments = @scope == 'stopped' ?
      @all_environments.stopped : @all_environments.available
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

  def stop
    return render_404 unless @environment.stoppable?

    action = @environment.stop_action
    new_action = action.active? ? action : action.play(current_user)
    redirect_to polymorphic_path([project.namespace.becomes(Namespace), project, new_action])
  end

  private

  def environment_params
    params.require(:environment).permit(:name, :external_url)
  end

  def environment
    @environment ||= project.environments.find(params[:id])
  end
end

class Projects::IntegrationsController < Projects::ApplicationController
  layout 'project'

  before_action :authorize_read_integration!
  before_action :authorize_create_integration!, only: [:new, :create]
  before_action :authorize_update_integration!, only: [:edit, :update, :destroy]
  before_action :integration, only: [:show, :edit, :update, :destroy]

  def index
    @integrations = project.integrations
  end

  def show
  end

  def new
    @integration = project.integrations.new
  end

  def edit
  end

  def create
    @integration = project.integrations.create(integration_params)

    if @integration.persisted?
      redirect_to namespace_project_integration_path(project.namespace, project, @integration)
    else
      render :new
    end
  end

  def update
    if @integration.update(integration_params)
      redirect_to namespace_project_integration_path(project.namespace, project, @integration)
    else
      render :edit
    end
  end

  def destroy
    if @integration.destroy
      flash[:notice] = 'Integration was successfully removed.'
    else
      flash[:alert] = 'Failed to remove integration.'
    end

    redirect_to namespace_project_integration_path(project.namespace, project)
  end

  private

  def integration_params
    params.require(:integration).permit(:name, :external_token)
  end

  def integration
    @integration ||= project.integrations.find(params[:id])
  end
end

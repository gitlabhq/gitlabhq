class Projects::EnvironmentsController < Projects::ApplicationController
  layout 'project'
  before_action :authorize_read_environment!
  before_action :authorize_create_environment!, only: [:new, :create]
  before_action :authorize_create_deployment!, only: [:stop]
  before_action :authorize_update_environment!, only: [:edit, :update]
  before_action :authorize_admin_environment!, only: [:terminal, :terminal_websocket_authorize]
  before_action :environment, only: [:show, :edit, :update, :stop, :terminal, :terminal_websocket_authorize]
  before_action :verify_api_request!, only: :terminal_websocket_authorize

  def index
    @scope = params[:scope]
    @environments = project.environments

    respond_to do |format|
      format.html
      format.json do
        render json: EnvironmentSerializer
          .new(project: @project, user: current_user)
          .represent(@environments)
      end
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

  def stop
    return render_404 unless @environment.stoppable?

    new_action = @environment.stop!(current_user)
    redirect_to polymorphic_path([project.namespace.becomes(Namespace), project, new_action])
  end

  def terminal
    # Currently, this acts as a hint to load the terminal details into the cache
    # if they aren't there already. In the future, users will need these details
    # to choose between terminals to connect to.
    @terminals = environment.terminals
  end

  # GET .../terminal.ws : implemented in gitlab-workhorse
  def terminal_websocket_authorize
    # Just return the first terminal for now. If the list is in the process of
    # being looked up, this may result in a 404 response, so the frontend
    # should retry those errors
    terminal = environment.terminals.try(:first)
    if terminal
      set_workhorse_internal_api_content_type
      render json: Gitlab::Workhorse.terminal_websocket(terminal)
    else
      render text: 'Not found', status: 404
    end
  end

  private

  def verify_api_request!
    Gitlab::Workhorse.verify_api_request!(request.headers)
  end

  def environment_params
    params.require(:environment).permit(:name, :external_url)
  end

  def environment
    @environment ||= project.environments.find(params[:id])
  end
end

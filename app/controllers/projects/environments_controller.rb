class Projects::EnvironmentsController < Projects::ApplicationController
  layout 'project'
  before_action :authorize_read_environment!
  before_action :authorize_create_environment!, only: [:new, :create]
  before_action :authorize_create_deployment!, only: [:stop]
  before_action :authorize_update_environment!, only: [:edit, :update]
  before_action :authorize_admin_environment!, only: [:terminal, :terminal_websocket_authorize]
  before_action :environment, only: [:show, :edit, :update, :stop, :terminal, :terminal_websocket_authorize, :metrics]
  before_action :verify_api_request!, only: :terminal_websocket_authorize

  def index
    @environments = project.environments
      .with_state(params[:scope] || :available)

    respond_to do |format|
      format.html
      format.json do
        Gitlab::PollingInterval.set_header(response, interval: 3_000)

        render json: {
          environments: EnvironmentSerializer
            .new(project: @project, current_user: @current_user)
            .with_pagination(request, response)
            .within_folders
            .represent(@environments),
          available_count: project.environments.available.count,
          stopped_count: project.environments.stopped.count
        }
      end
    end
  end

  def folder
    folder_environments = project.environments.where(environment_type: params[:id])
    @environments = folder_environments.with_state(params[:scope] || :available)
      .order(:name)
    @folder = params[:id]

    respond_to do |format|
      format.html
      format.json do
        render json: {
          environments: EnvironmentSerializer
            .new(project: @project, current_user: @current_user)
            .with_pagination(request, response)
            .represent(@environments),
          available_count: folder_environments.available.count,
          stopped_count: folder_environments.stopped.count
        }
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
      redirect_to project_environment_path(project, @environment)
    else
      render :new
    end
  end

  def update
    if @environment.update(environment_params)
      redirect_to project_environment_path(project, @environment)
    else
      render :edit
    end
  end

  def stop
    return render_404 unless @environment.available?

    stop_action = @environment.stop_with_action!(current_user)

    action_or_env_url =
      if stop_action
        polymorphic_url([project.namespace.becomes(Namespace), project, stop_action])
      else
        project_environment_url(project, @environment)
      end

    respond_to do |format|
      format.html { redirect_to action_or_env_url }
      format.json { render json: { redirect_url: action_or_env_url } }
    end
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

  def metrics
    # Currently, this acts as a hint to load the metrics details into the cache
    # if they aren't there already
    @metrics = environment.metrics || {}

    respond_to do |format|
      format.html
      format.json do
        render json: @metrics, status: @metrics.any? ? :ok : :no_content
      end
    end
  end

  def additional_metrics
    respond_to do |format|
      format.json do
        additional_metrics = environment.additional_metrics || {}

        render json: additional_metrics, status: additional_metrics.any? ? :ok : :no_content
      end
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

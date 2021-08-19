# frozen_string_literal: true

class Projects::EnvironmentsController < Projects::ApplicationController
  # Metrics dashboard code is getting decoupled from environments and is being moved
  # into app/controllers/projects/metrics_dashboard_controller.rb
  # See https://gitlab.com/gitlab-org/gitlab/-/issues/226002 for more details.

  include MetricsDashboard

  layout 'project'

  before_action only: [:metrics, :additional_metrics, :metrics_dashboard] do
    authorize_metrics_dashboard!

    push_frontend_feature_flag(:prometheus_computed_alerts)
    push_frontend_feature_flag(:disable_metric_dashboard_refresh_rate)
  end

  before_action :authorize_read_environment!, except: [:metrics, :additional_metrics, :metrics_dashboard, :metrics_redirect]
  before_action :authorize_create_environment!, only: [:new, :create]
  before_action :authorize_stop_environment!, only: [:stop]
  before_action :authorize_update_environment!, only: [:edit, :update, :cancel_auto_stop]
  before_action :authorize_admin_environment!, only: [:terminal, :terminal_websocket_authorize]
  before_action :environment, only: [:show, :edit, :update, :stop, :terminal, :terminal_websocket_authorize, :metrics, :cancel_auto_stop]
  before_action :verify_api_request!, only: :terminal_websocket_authorize
  before_action :expire_etag_cache, only: [:index], unless: -> { request.format.json? }
  after_action :expire_etag_cache, only: [:cancel_auto_stop]

  feature_category :continuous_delivery

  def index
    @environments = project.environments
      .with_state(params[:scope] || :available)
    @project = ProjectPresenter.new(project, current_user: current_user)

    respond_to do |format|
      format.html
      format.json do
        Gitlab::PollingInterval.set_header(response, interval: 3_000)
        environments_count_by_state = project.environments.count_by_state

        render json: {
          environments: serialize_environments(request, response, params[:nested]),
          review_app: serialize_review_app,
          available_count: environments_count_by_state[:available],
          stopped_count: environments_count_by_state[:stopped]
        }
      end
    end
  end

  # Returns all environments for a given folder
  # rubocop: disable CodeReuse/ActiveRecord
  def folder
    folder_environments = project.environments.where(environment_type: params[:id])
    @environments = folder_environments.with_state(params[:scope] || :available)
      .order(:name)
    @folder = params[:id]

    respond_to do |format|
      format.html
      format.json do
        render json: {
          environments: serialize_environments(request, response),
          available_count: folder_environments.available.count,
          stopped_count: folder_environments.stopped.count
        }
      end
    end
  end
  # rubocop: enable CodeReuse/ActiveRecord

  # rubocop: disable CodeReuse/ActiveRecord
  def show
    @deployments = environment.deployments.order(id: :desc).page(params[:page])
  end
  # rubocop: enable CodeReuse/ActiveRecord

  def new
    @environment = project.environments.new
  end

  def edit
  end

  def create
    @environment = project.environments.create(environment_params)

    if @environment.persisted?
      render json: { environment: @environment, path: project_environment_path(project, @environment) }
    else
      render json: { message: @environment.errors.full_messages }, status: :bad_request
    end
  end

  def update
    if @environment.update(environment_params)
      render json: { environment: @environment, path: project_environment_path(project, @environment) }
    else
      render json: { message: @environment.errors.full_messages }, status: :bad_request
    end
  end

  def stop
    return render_404 unless @environment.available?

    stop_action = @environment.stop_with_action!(current_user)

    action_or_env_url =
      if stop_action
        polymorphic_url([project, stop_action])
      else
        project_environment_url(project, @environment)
      end

    respond_to do |format|
      format.html { redirect_to action_or_env_url }
      format.json { render json: { redirect_url: action_or_env_url } }
    end
  end

  def cancel_auto_stop
    result = Environments::ResetAutoStopService.new(project, current_user)
      .execute(environment)

    if result[:status] == :success
      respond_to do |format|
        message = _('Auto stop successfully canceled.')

        format.html { redirect_back_or_default(default: { action: 'show' }, options: { notice: message }) }
        format.json { render json: { message: message }, status: :ok }
      end
    else
      respond_to do |format|
        message = result[:message]

        format.html { redirect_back_or_default(default: { action: 'show' }, options: { alert: message }) }
        format.json { render json: { message: message }, status: :unprocessable_entity }
      end
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
      render json: Gitlab::Workhorse.channel_websocket(terminal)
    else
      render html: 'Not found', status: :not_found
    end
  end

  def metrics_redirect
    redirect_to project_metrics_dashboard_path(project)
  end

  def metrics
    respond_to do |format|
      format.html do
        redirect_to project_metrics_dashboard_path(project, environment: environment )
      end
      format.json do
        # Currently, this acts as a hint to load the metrics details into the cache
        # if they aren't there already
        @metrics = environment.metrics || {}

        render json: @metrics, status: @metrics.any? ? :ok : :no_content
      end
    end
  end

  def additional_metrics
    respond_to do |format|
      format.json do
        additional_metrics = environment.additional_metrics(*metrics_params) || {}

        render json: additional_metrics, status: additional_metrics.any? ? :ok : :no_content
      end
    end
  end

  def search
    respond_to do |format|
      format.json do
        environment_names = search_environment_names

        render json: environment_names, status: environment_names.any? ? :ok : :no_content
      end
    end
  end

  private

  def verify_api_request!
    Gitlab::Workhorse.verify_api_request!(request.headers)
  end

  def expire_etag_cache
    # this forces to reload json content
    Gitlab::EtagCaching::Store.new.tap do |store|
      store.touch(project_environments_path(project, format: :json))
    end
  end

  def environment_params
    params.require(:environment).permit(:name, :external_url)
  end

  def environment
    @environment ||= project.environments.find(params[:id])
  end

  def metrics_params
    params.require([:start, :end])
  end

  def metrics_dashboard_params
    params
      .permit(:embedded, :group, :title, :y_label, :dashboard_path, :environment, :sample_metrics, :embed_json)
      .merge(dashboard_path: params[:dashboard], environment: environment)
  end

  def include_all_dashboards?
    !params[:embedded]
  end

  def search_environment_names
    return [] unless params[:query]

    project.environments.for_name_like(params[:query]).pluck_names
  end

  def serialize_environments(request, response, nested = false)
    EnvironmentSerializer
      .new(project: @project, current_user: @current_user)
      .tap { |serializer| serializer.within_folders if nested }
      .with_pagination(request, response)
      .represent(@environments)
  end

  def serialize_review_app
    ReviewAppSetupSerializer.new(current_user: @current_user).represent(@project)
  end

  def authorize_stop_environment!
    access_denied! unless can?(current_user, :stop_environment, environment)
  end

  def authorize_update_environment!
    access_denied! unless can?(current_user, :update_environment, environment)
  end
end

Projects::EnvironmentsController.prepend_mod_with('Projects::EnvironmentsController')

# frozen_string_literal: true

class Projects::EnvironmentsController < Projects::ApplicationController
  include ProductAnalyticsTracking
  include KasCookie

  MIN_SEARCH_LENGTH = 3
  ACTIVE_STATES = %i[available stopping].freeze
  SCOPES_TO_STATES = { "active" => ACTIVE_STATES, "stopped" => %i[stopped] }.freeze

  layout 'project'

  before_action only: [:folder] do
    push_frontend_feature_flag(:environments_folder_new_look, project)
  end

  before_action only: [:show] do
    push_frontend_feature_flag(:k8s_tree_view, project)
    push_frontend_feature_flag(:use_websocket_for_k8s_watch, project)
  end

  before_action :authorize_read_environment!
  before_action :authorize_create_environment!, only: [:new, :create]
  before_action :authorize_stop_environment!, only: [:stop]
  before_action :authorize_update_environment!, only: [:edit, :update, :cancel_auto_stop]
  before_action :authorize_admin_environment!, only: [:terminal, :terminal_websocket_authorize]
  before_action :environment,
    only: [:show, :edit, :update, :stop, :terminal, :terminal_websocket_authorize, :cancel_auto_stop, :k8s]
  before_action :verify_api_request!, only: :terminal_websocket_authorize
  before_action :expire_etag_cache, only: [:index], unless: -> { request.format.json? }
  before_action :set_kas_cookie, only: [:edit, :new, :show, :k8s], if: -> { current_user && request.format.html? }
  after_action :expire_etag_cache, only: [:cancel_auto_stop]

  track_event :index, :folder, :show, :new, :edit, :create, :update, :stop, :cancel_auto_stop, :terminal, :k8s,
    name: 'users_visiting_environments_pages'

  feature_category :continuous_delivery
  urgency :low

  def index
    @project = ProjectPresenter.new(project, current_user: current_user)

    respond_to do |format|
      format.html
      format.json do
        states = SCOPES_TO_STATES.fetch(params[:scope], ACTIVE_STATES)
        @environments = search_environments.with_state(states)

        environments_count_by_state = search_environments.count_by_state

        Gitlab::PollingInterval.set_header(response, interval: 3_000)
        render json: {
          environments: serialize_environments(request, response, params[:nested]),
          review_app: serialize_review_app,
          can_stop_stale_environments: can?(current_user, :stop_environment, @project),
          available_count: environments_count_by_state[:available],
          active_count: environments_count_by_state[:available] + environments_count_by_state[:stopping],
          stopped_count: environments_count_by_state[:stopped]
        }
      end
    end
  end

  # Returns all environments for a given folder
  # rubocop: disable CodeReuse/ActiveRecord
  def folder
    @folder = params[:id]

    respond_to do |format|
      format.html
      format.json do
        states = SCOPES_TO_STATES.fetch(params[:scope], ACTIVE_STATES)
        folder_environments = search_environments(type: params[:id])

        @environments = folder_environments.with_state(states)
          .order(:name)

        render json: {
          environments: serialize_environments(request, response),
          available_count: folder_environments.available.count,
          active_count: folder_environments.active.count,
          stopped_count: folder_environments.stopped.count
        }
      end
    end
  end
  # rubocop: enable CodeReuse/ActiveRecord

  def show; end

  def new
    @environment = project.environments.new
  end

  def edit; end

  def k8s
    render action: :show
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

    service_response = Environments::StopService.new(project, current_user).execute(@environment)
    return render_403 unless service_response.success?

    job = service_response[:actions].first if service_response[:actions]&.count == 1

    action_or_env_url =
      if job
        project_job_url(project, job)
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

  def search
    respond_to do |format|
      format.json do
        environment_names = search_environment_names

        render json: environment_names, status: environment_names.any? ? :ok : :no_content
      end
    end
  end

  private

  def deployments
    environment
      .deployments
      .with_environment_page_associations
      .ordered
      .page(params[:page])
  end

  def verify_api_request!
    Gitlab::Workhorse.verify_api_request!(request.headers)
  end

  def expire_etag_cache
    # this forces to reload json content
    Gitlab::EtagCaching::Store.new.tap do |store|
      store.touch(project_environments_path(project, format: :json))
    end
  end

  def allowed_environment_attributes
    attributes = [:external_url]
    attributes << :name if action_name == "create"
    attributes
  end

  def environment_params
    params.require(:environment).permit(allowed_environment_attributes)
  end

  def environment
    @environment ||= project.environments.find(params[:id])
  end

  def search_environments(type: nil)
    search = params[:search] if params[:search] && params[:search].length >= MIN_SEARCH_LENGTH

    @search_environments ||= Environments::EnvironmentsFinder.new(
      project,
      current_user,
      type: type,
      search: search
    ).execute
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

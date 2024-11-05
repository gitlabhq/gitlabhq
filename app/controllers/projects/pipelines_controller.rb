# frozen_string_literal: true

class Projects::PipelinesController < Projects::ApplicationController
  include ::Gitlab::Utils::StrongMemoize
  include ProductAnalyticsTracking
  include ProjectStatsRefreshConflictsGuard

  urgency :low, [
    :index, :new, :builds, :show, :failures, :create,
    :stage, :retry, :cancel, :test_report,
    :charts, :destroy, :status, :manual_variables
  ]

  before_action only: [:charts] do
    push_frontend_feature_flag(:ci_improved_project_pipeline_analytics, project)
  end

  before_action :disable_query_limiting, only: [:create, :retry]
  before_action :pipeline, except: [:index, :new, :create, :charts]
  before_action :set_pipeline_path, only: [:show]
  before_action :authorize_read_pipeline!
  before_action :authorize_read_build!, only: [:index]
  before_action :authorize_read_build_on_pipeline!, only: [:show]
  before_action :authorize_read_ci_cd_analytics!, only: [:charts]
  before_action :authorize_create_pipeline!, only: [:new, :create]
  before_action :authorize_update_pipeline!, only: [:retry]
  before_action :authorize_cancel_pipeline!, only: [:cancel]
  before_action :ensure_pipeline, only: [:show, :downloadable_artifacts]
  before_action :reject_if_build_artifacts_size_refreshing!, only: [:destroy]
  before_action only: [:show, :builds, :failures, :test_report, :manual_variables] do
    push_frontend_feature_flag(:ci_show_manual_variables_in_pipeline, project)
  end

  # Will be removed with https://gitlab.com/gitlab-org/gitlab/-/issues/225596
  before_action :redirect_for_legacy_scope_filter, only: [:index], if: -> { request.format.html? }

  around_action :allow_gitaly_ref_name_caching, only: [:index, :show]

  track_event :charts,
    name: 'p_analytics_pipelines',
    action: 'perform_analytics_usage_action',
    label: 'redis_hll_counters.analytics.analytics_total_unique_counts_monthly',
    destinations: %i[redis_hll snowplow]

  track_internal_event :charts, name: 'p_analytics_ci_cd_pipelines', conditions: -> { should_track_ci_cd_pipelines? }
  track_internal_event :charts, name: 'p_analytics_ci_cd_deployment_frequency', conditions: -> { should_track_ci_cd_deployment_frequency? }
  track_internal_event :charts, name: 'p_analytics_ci_cd_lead_time', conditions: -> { should_track_ci_cd_lead_time? }
  track_internal_event :charts, name: 'visit_ci_cd_time_to_restore_service_tab', conditions: -> { should_track_visit_ci_cd_time_to_restore_service_tab? }
  track_internal_event :charts, name: 'visit_ci_cd_failure_rate_tab', conditions: -> { should_track_visit_ci_cd_change_failure_tab? }

  wrap_parameters Ci::Pipeline

  POLLING_INTERVAL = 10_000

  feature_category :continuous_integration, [
    :charts, :show, :stage, :cancel, :retry,
    :builds, :failures, :status,
    :index, :new, :destroy, :manual_variables
  ]
  feature_category :pipeline_composition, [:create]
  feature_category :code_testing, [:test_report]
  feature_category :job_artifacts, [:downloadable_artifacts]

  def index
    @pipelines = Ci::PipelinesFinder
      .new(project, current_user, index_params)
      .execute
      .page(params[:page])

    @pipelines_count = limited_pipelines_count(project)

    respond_to do |format|
      format.html
      format.json do
        Gitlab::PollingInterval.set_header(response, interval: POLLING_INTERVAL)

        render json: {
          pipelines: serialize_pipelines,
          count: {
            all: @pipelines_count
          }
        }
      end
    end
  end

  def new
    @pipeline = project.all_pipelines.new(ref: @project.default_branch)
  end

  def create
    service_response = Ci::CreatePipelineService
      .new(project, current_user, create_params)
      .execute(:web, ignore_skip_ci: true, save_on_errors: false)

    @pipeline = service_response.payload

    respond_to do |format|
      format.html do
        if service_response.success?
          redirect_to project_pipeline_path(project, @pipeline)
        else
          render 'new', status: :bad_request
        end
      end
      format.json do
        if service_response.success?
          render json: PipelineSerializer.new(project: project, current_user: current_user).represent(@pipeline),
            status: :created
        else
          bad_request_json = {
            errors: @pipeline.error_messages.map(&:content),
            warnings: @pipeline.warning_messages(limit: ::Gitlab::Ci::Warnings::MAX_LIMIT).map(&:content),
            total_warnings: @pipeline.warning_messages.length
          }
          render json: bad_request_json, status: :bad_request
        end
      end
    end
  end

  def show
    Gitlab::QueryLimiting.disable!('https://gitlab.com/gitlab-org/gitlab/-/issues/26657')

    respond_to do |format|
      format.html { render_show }
      format.json do
        Gitlab::PollingInterval.set_header(response, interval: POLLING_INTERVAL)

        render json: PipelineSerializer
          .new(project: @project, current_user: @current_user)
          .represent(@pipeline, show_represent_params)
      end
    end
  end

  def destroy
    ::Ci::DestroyPipelineService.new(project, current_user).execute(pipeline)

    redirect_to project_pipelines_path(project), status: :see_other
  end

  def builds
    render_show
  end

  def failures
    if @pipeline.failed_builds.present?
      render_show
    else
      redirect_to pipeline_path(@pipeline)
    end
  end

  def status
    render json: PipelineSerializer
      .new(project: @project, current_user: @current_user)
      .represent_status(@pipeline)
  end

  def stage
    @stage = pipeline.stage(params[:stage])
    return not_found unless @stage

    return unless stage_stale?

    render json: StageSerializer
      .new(project: @project, current_user: @current_user)
      .represent(@stage, details: true, retried: params[:retried])
  end

  def retry
    # Check for access before execution to allow for async execution while still returning access results
    access_response = ::Ci::RetryPipelineService.new(@project, current_user).check_access(pipeline)

    if access_response.error?
      response = { json: { errors: [access_response.message] }, status: access_response.http_status }
    else
      response = { json: {}, status: :no_content }
      ::Ci::RetryPipelineWorker.perform_async(pipeline.id, current_user.id) # rubocop:disable CodeReuse/Worker
    end

    respond_to do |format|
      format.json do
        render response
      end
    end
  end

  def cancel
    ::Ci::CancelPipelineService.new(pipeline: pipeline, current_user: @current_user).execute

    respond_to do |format|
      format.html do
        redirect_back_or_default default: project_pipelines_path(project)
      end

      format.json { head :no_content }
    end
  end

  def test_report
    respond_to do |format|
      format.html do
        render_show
      end
      format.json do
        render json: TestReportSerializer
          .new(current_user: @current_user)
          .represent(pipeline_test_report, project: project, details: true)
      end
    end
  end

  def manual_variables
    return render_404 unless ::Feature.enabled?(:ci_show_manual_variables_in_pipeline, project)

    render_show
  end

  def downloadable_artifacts
    render json: Ci::DownloadableArtifactSerializer.new(
      project: project,
      current_user: current_user
    ).represent(@pipeline)
  end

  private

  def serialize_pipelines
    PipelineSerializer
      .new(project: @project, current_user: @current_user)
      .with_pagination(request, response)
      .represent(
        @pipelines,
        disable_coverage: true,
        disable_failed_builds: true,
        disable_manual_and_scheduled_actions: true,
        preload: true,
        preload_statuses: false,
        preload_downstream_statuses: false
      )
  end

  def render_show
    @stages = @pipeline.stages

    respond_to do |format|
      format.html do
        render 'show'
      end
    end
  end

  def show_represent_params
    { grouped: true, expanded: params[:expanded].to_a.map(&:to_i) }
  end

  def create_params
    params.require(:pipeline).permit(:ref, variables_attributes: %i[key variable_type secret_value])
  end

  def ensure_pipeline
    render_404 unless pipeline
  end

  def redirect_for_legacy_scope_filter
    return unless %w[running pending].include?(params[:scope])

    redirect_to url_for(safe_params.except(:scope).merge(status: safe_params[:scope])), status: :moved_permanently
  end

  def stage_stale?
    return true if Feature.disabled?(:pipeline_stage_set_last_modified, @current_user)

    last_modified = [@stage.updated_at.utc, @stage.statuses.maximum(:updated_at)].max

    stale?(last_modified: last_modified, etag: @stage)
  end

  # rubocop: disable CodeReuse/ActiveRecord
  def pipeline
    return @pipeline if defined?(@pipeline)

    pipelines =
      if find_latest_pipeline?
        project.latest_pipelines(ref: params['ref'], limit: 100)
      else
        project.all_pipelines.id_in(params[:id])
      end

    @pipeline = pipelines
      .includes(builds: :tags, user: :status)
      .take
      &.present(current_user: current_user)

    @pipeline || not_found
  end
  # rubocop: enable CodeReuse/ActiveRecord

  def set_pipeline_path
    @pipeline_path ||= if find_latest_pipeline?
                         latest_project_pipelines_path(@project, params['ref'])
                       else
                         project_pipeline_path(@project, @pipeline)
                       end
  end

  def find_latest_pipeline?
    params[:id].blank? && params[:latest]
  end

  def disable_query_limiting
    # Also see https://gitlab.com/gitlab-org/gitlab/-/issues/20785
    Gitlab::QueryLimiting.disable!('https://gitlab.com/gitlab-org/gitlab/-/issues/20784')
  end

  def authorize_update_pipeline!
    access_denied! unless can?(current_user, :update_pipeline, @pipeline)
  end

  def authorize_cancel_pipeline!
    access_denied! unless can?(current_user, :cancel_pipeline, @pipeline)
  end

  def authorize_read_build_on_pipeline!
    access_denied! unless can?(current_user, :read_build, @pipeline)
  end

  def limited_pipelines_count(project, scope = nil)
    finder = Ci::PipelinesFinder.new(project, current_user, index_params.merge(scope: scope))

    view_context.limited_counter_with_delimiter(finder.execute)
  end

  def pipeline_test_report
    strong_memoize(:pipeline_test_report) do
      @pipeline.test_reports.tap do |reports|
        reports.with_attachment! if params[:scope] == 'with_attachment'
      end
    end
  end

  def index_params
    params.permit(:scope, :username, :ref, :status, :source)
  end

  def should_track_ci_cd_pipelines?
    params[:chart].blank? || params[:chart] == 'pipelines'
  end

  def should_track_ci_cd_deployment_frequency?
    params[:chart] == 'deployment-frequency'
  end

  def should_track_ci_cd_lead_time?
    params[:chart] == 'lead-time'
  end

  def should_track_visit_ci_cd_time_to_restore_service_tab?
    params[:chart] == 'time-to-restore-service'
  end

  def should_track_visit_ci_cd_change_failure_tab?
    params[:chart] == 'change-failure-rate'
  end

  def tracking_namespace_source
    project.namespace
  end

  def tracking_project_source
    project
  end
end

Projects::PipelinesController.prepend_mod_with('Projects::PipelinesController')

# frozen_string_literal: true

class Projects::PipelinesController < Projects::ApplicationController
  include ::Gitlab::Utils::StrongMemoize
  include Analytics::UniqueVisitsHelper

  before_action :disable_query_limiting, only: [:create, :retry]
  before_action :pipeline, except: [:index, :new, :create, :charts, :config_variables]
  before_action :set_pipeline_path, only: [:show]
  before_action :authorize_read_pipeline!
  before_action :authorize_read_build!, only: [:index]
  before_action :authorize_read_analytics!, only: [:charts]
  before_action :authorize_create_pipeline!, only: [:new, :create, :config_variables]
  before_action :authorize_update_pipeline!, only: [:retry, :cancel]
  before_action do
    push_frontend_feature_flag(:pipeline_graph_layers_view, project, type: :development, default_enabled: :yaml)
    push_frontend_feature_flag(:graphql_pipeline_details, project, type: :development, default_enabled: :yaml)
    push_frontend_feature_flag(:graphql_pipeline_details_users, current_user, type: :development, default_enabled: :yaml)
  end
  before_action :ensure_pipeline, only: [:show, :downloadable_artifacts]

  # Will be removed with https://gitlab.com/gitlab-org/gitlab/-/issues/225596
  before_action :redirect_for_legacy_scope_filter, only: [:index], if: -> { request.format.html? }

  around_action :allow_gitaly_ref_name_caching, only: [:index, :show]

  track_unique_visits :charts, target_id: 'p_analytics_pipelines'

  wrap_parameters Ci::Pipeline

  POLLING_INTERVAL = 10_000

  feature_category :continuous_integration, [
                     :charts, :show, :config_variables, :stage, :cancel, :retry,
                     :builds, :dag, :failures, :status, :downloadable_artifacts,
                     :index, :create, :new, :destroy
                   ]
  feature_category :code_testing, [:test_report]

  def index
    @pipelines = Ci::PipelinesFinder
      .new(project, current_user, index_params)
      .execute
      .page(params[:page])

    @pipelines_count = limited_pipelines_count(project)

    respond_to do |format|
      format.html do
        enable_code_quality_walkthrough_experiment
        enable_ci_runner_templates_experiment
      end
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
    @pipeline = Ci::CreatePipelineService
      .new(project, current_user, create_params)
      .execute(:web, ignore_skip_ci: true, save_on_errors: false)

    respond_to do |format|
      format.html do
        if @pipeline.created_successfully?
          redirect_to project_pipeline_path(project, @pipeline)
        else
          render 'new', status: :bad_request
        end
      end
      format.json do
        if @pipeline.created_successfully?
          render json: PipelineSerializer
                         .new(project: project, current_user: current_user)
                         .represent(@pipeline),
                 status: :created
        else
          render json: { errors: @pipeline.error_messages.map(&:content),
                         warnings: @pipeline.warning_messages(limit: ::Gitlab::Ci::Warnings::MAX_LIMIT).map(&:content),
                         total_warnings: @pipeline.warning_messages.length },
                 status: :bad_request
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

  def dag
    respond_to do |format|
      format.html { render_show }
      format.json do
        render json: Ci::DagPipelineSerializer
          .new(project: @project, current_user: @current_user)
          .represent(@pipeline)
      end
    end
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
    @stage = pipeline.legacy_stage(params[:stage])
    return not_found unless @stage

    render json: StageSerializer
      .new(project: @project, current_user: @current_user)
      .represent(@stage, details: true, retried: params[:retried])
  end

  def retry
    ::Ci::RetryPipelineWorker.perform_async(pipeline.id, current_user.id) # rubocop:disable CodeReuse/Worker

    respond_to do |format|
      format.html do
        redirect_back_or_default default: project_pipelines_path(project)
      end

      format.json { head :no_content }
    end
  end

  def cancel
    pipeline.cancel_running

    respond_to do |format|
      format.html do
        redirect_back_or_default default: project_pipelines_path(project)
      end

      format.json { head :no_content }
    end
  end

  def test_report
    respond_to do |format|
      format.html { render_show }
      format.json do
        render json: TestReportSerializer
          .new(current_user: @current_user)
          .represent(pipeline_test_report, project: project, details: true)
      end
    end
  end

  def config_variables
    respond_to do |format|
      format.json do
        result = Ci::ListConfigVariablesService.new(@project, current_user).execute(params[:sha])

        result.nil? ? head(:no_content) : render(json: result)
      end
    end
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
      .represent(@pipelines, disable_coverage: true, preload: true, code_quality_walkthrough: params[:code_quality_walkthrough].present?)
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

  # rubocop: disable CodeReuse/ActiveRecord
  def pipeline
    @pipeline ||= if params[:id].blank? && params[:latest]
                    latest_pipeline
                  else
                    project
                      .all_pipelines
                      .includes(builds: :tags, user: :status)
                      .find_by!(id: params[:id])
                      .present(current_user: current_user)
                  end
  end
  # rubocop: enable CodeReuse/ActiveRecord

  def set_pipeline_path
    @pipeline_path ||= if params[:id].blank? && params[:latest]
                         latest_project_pipelines_path(@project, params['ref'])
                       else
                         project_pipeline_path(@project, @pipeline)
                       end
  end

  def latest_pipeline
    @project.latest_pipeline(params['ref'])
            &.present(current_user: current_user)
  end

  def disable_query_limiting
    # Also see https://gitlab.com/gitlab-org/gitlab/-/issues/20785
    Gitlab::QueryLimiting.disable!('https://gitlab.com/gitlab-org/gitlab/-/issues/20784')
  end

  def authorize_update_pipeline!
    return access_denied! unless can?(current_user, :update_pipeline, @pipeline)
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
    params.permit(:scope, :username, :ref, :status)
  end

  def enable_code_quality_walkthrough_experiment
    experiment(:code_quality_walkthrough, namespace: project.root_ancestor) do |e|
      e.exclude! unless current_user
      e.exclude! unless can?(current_user, :create_pipeline, project)
      e.exclude! unless project.root_ancestor.recent?
      e.exclude! if @pipelines_count.to_i > 0
      e.exclude! if helpers.has_gitlab_ci?(project)

      e.control {}
      e.candidate {}
      e.record!
    end
  end

  def enable_ci_runner_templates_experiment
    experiment(:ci_runner_templates, namespace: project.root_ancestor) do |e|
      e.exclude! unless current_user
      e.exclude! unless can?(current_user, :create_pipeline, project)
      e.exclude! if @pipelines_count.to_i > 0
      e.exclude! if helpers.has_gitlab_ci?(project)

      e.control {}
      e.candidate {}
      e.record!
    end
  end
end

Projects::PipelinesController.prepend_mod_with('Projects::PipelinesController')

# frozen_string_literal: true

class Projects::PipelinesController < Projects::ApplicationController
  include ::Gitlab::Utils::StrongMemoize
  include Analytics::UniqueVisitsHelper

  before_action :whitelist_query_limiting, only: [:create, :retry]
  before_action :pipeline, except: [:index, :new, :create, :charts, :config_variables]
  before_action :set_pipeline_path, only: [:show]
  before_action :authorize_read_pipeline!
  before_action :authorize_read_build!, only: [:index]
  before_action :authorize_create_pipeline!, only: [:new, :create, :config_variables]
  before_action :authorize_update_pipeline!, only: [:retry, :cancel]
  before_action do
    push_frontend_feature_flag(:dag_pipeline_tab, project, default_enabled: true)
    push_frontend_feature_flag(:pipelines_security_report_summary, project)
    push_frontend_feature_flag(:new_pipeline_form, project, default_enabled: true)
    push_frontend_feature_flag(:graphql_pipeline_header, project, type: :development, default_enabled: false)
    push_frontend_feature_flag(:graphql_pipeline_details, project, type: :development, default_enabled: false)
    push_frontend_feature_flag(:new_pipeline_form_prefilled_vars, project, type: :development)
  end
  before_action :ensure_pipeline, only: [:show]

  # Will be removed with https://gitlab.com/gitlab-org/gitlab/-/issues/225596
  before_action :redirect_for_legacy_scope_filter, only: [:index], if: -> { request.format.html? }

  around_action :allow_gitaly_ref_name_caching, only: [:index, :show]

  track_unique_visits :charts, target_id: 'p_analytics_pipelines'

  wrap_parameters Ci::Pipeline

  POLLING_INTERVAL = 10_000

  feature_category :continuous_integration

  def index
    @pipelines = Ci::PipelinesFinder
      .new(project, current_user, index_params)
      .execute
      .page(params[:page])
      .per(30)

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
    Gitlab::QueryLimiting.whitelist('https://gitlab.com/gitlab-org/gitlab/-/issues/26657')

    respond_to do |format|
      format.html
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

  # TODO: This endpoint is used by mini-pipeline-graph
  # TODO: This endpoint should be migrated to `stage.json`
  def stage_ajax
    @stage = pipeline.legacy_stage(params[:stage])
    return not_found unless @stage

    render json: { html: view_to_html_string('projects/pipelines/_stage') }
  end

  def retry
    pipeline.retry_failed(current_user)

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

  def charts
    @charts = {}
    @charts[:week] = Gitlab::Ci::Charts::WeekChart.new(project)
    @charts[:month] = Gitlab::Ci::Charts::MonthChart.new(project)
    @charts[:year] = Gitlab::Ci::Charts::YearChart.new(project)
    @charts[:pipeline_times] = Gitlab::Ci::Charts::PipelineTime.new(project)

    @counts = {}
    @counts[:total] = @project.all_pipelines.count(:all)
    @counts[:success] = @project.all_pipelines.success.count(:all)
    @counts[:failed] = @project.all_pipelines.failed.count(:all)
    @counts[:total_duration] = @project.all_pipelines.total_duration
  end

  def test_report
    respond_to do |format|
      format.html do
        render 'show'
      end

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

  private

  def serialize_pipelines
    PipelineSerializer
      .new(project: @project, current_user: @current_user)
      .with_pagination(request, response)
      .represent(@pipelines, disable_coverage: true, preload: true)
  end

  def render_show
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

  def whitelist_query_limiting
    # Also see https://gitlab.com/gitlab-org/gitlab-foss/issues/42343
    Gitlab::QueryLimiting.whitelist('https://gitlab.com/gitlab-org/gitlab-foss/issues/42339')
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
end

Projects::PipelinesController.prepend_if_ee('EE::Projects::PipelinesController')

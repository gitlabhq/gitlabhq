# frozen_string_literal: true

class Projects::PipelinesController < Projects::ApplicationController
  include ::Gitlab::Utils::StrongMemoize

  before_action :whitelist_query_limiting, only: [:create, :retry]
  before_action :pipeline, except: [:index, :new, :create, :charts]
  before_action :set_pipeline_path, only: [:show]
  before_action :authorize_read_pipeline!
  before_action :authorize_read_build!, only: [:index]
  before_action :authorize_create_pipeline!, only: [:new, :create]
  before_action :authorize_update_pipeline!, only: [:retry, :cancel]
  before_action do
    push_frontend_feature_flag(:junit_pipeline_view)
  end

  around_action :allow_gitaly_ref_name_caching, only: [:index, :show]

  wrap_parameters Ci::Pipeline

  POLLING_INTERVAL = 10_000

  def index
    @scope = params[:scope]
    @pipelines = PipelinesFinder
      .new(project, current_user, scope: @scope)
      .execute
      .page(params[:page])
      .per(30)

    @running_count = limited_pipelines_count(project, 'running')
    @pending_count = limited_pipelines_count(project, 'pending')
    @finished_count = limited_pipelines_count(project, 'finished')
    @pipelines_count = limited_pipelines_count(project)

    respond_to do |format|
      format.html
      format.json do
        Gitlab::PollingInterval.set_header(response, interval: POLLING_INTERVAL)

        render json: {
          pipelines: serialize_pipelines,
          count: {
            all: @pipelines_count,
            running: @running_count,
            pending: @pending_count,
            finished: @finished_count
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

    if @pipeline.persisted?
      redirect_to project_pipeline_path(project, @pipeline)
    else
      render 'new'
    end
  end

  def show
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
  end

  def test_report
    return unless Feature.enabled?(:junit_pipeline_view, project)

    respond_to do |format|
      format.html do
        render 'show'
      end

      format.json do
        if pipeline_test_report == :error
          render json: { status: :error_parsing_report }
        else
          render json: TestReportSerializer
            .new(current_user: @current_user)
            .represent(pipeline_test_report)
        end
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
    @project.latest_pipeline_for_ref(params['ref'])
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
    finder = PipelinesFinder.new(project, current_user, scope: scope)

    view_context.limited_counter_with_delimiter(finder.execute)
  end

  def pipeline_test_report
    strong_memoize(:pipeline_test_report) do
      @pipeline.test_reports
    rescue Gitlab::Ci::Parsers::ParserError
      :error
    end
  end
end

Projects::PipelinesController.prepend_if_ee('EE::Projects::PipelinesController')

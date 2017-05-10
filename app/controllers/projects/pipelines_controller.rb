class Projects::PipelinesController < Projects::ApplicationController
  before_action :pipeline, except: [:index, :new, :create, :charts]
  before_action :commit, only: [:show, :builds, :failures]
  before_action :authorize_read_pipeline!
  before_action :authorize_create_pipeline!, only: [:new, :create]
  before_action :authorize_update_pipeline!, only: [:retry, :cancel]
  before_action :builds_enabled, only: :charts

  wrap_parameters Ci::Pipeline

  def index
    @scope = params[:scope]
    @pipelines = PipelinesFinder
      .new(project, scope: @scope)
      .execute
      .page(params[:page])
      .per(30)

    @running_count = PipelinesFinder
      .new(project, scope: 'running').execute.count

    @pending_count = PipelinesFinder
      .new(project, scope: 'pending').execute.count

    @finished_count = PipelinesFinder
      .new(project, scope: 'finished').execute.count

    @pipelines_count = PipelinesFinder
      .new(project).execute.count

    respond_to do |format|
      format.html
      format.json do
        Gitlab::PollingInterval.set_header(response, interval: 10_000)

        render json: {
          pipelines: PipelineSerializer
            .new(project: @project, current_user: @current_user)
            .with_pagination(request, response)
            .represent(@pipelines),
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
    @pipeline = project.pipelines.new(ref: @project.default_branch)
  end

  def create
    @pipeline = Ci::CreatePipelineService
      .new(project, current_user, create_params)
      .execute(ignore_skip_ci: true, save_on_errors: false)
    unless @pipeline.persisted?
      render 'new'
      return
    end

    redirect_to namespace_project_pipeline_path(project.namespace, project, @pipeline)
  end

  def show
  end

  def builds
    render_show
  end

  def failures
    if @pipeline.statuses.latest.failed.present?
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

    respond_to do |format|
      format.json { render json: { html: view_to_html_string('projects/pipelines/_stage') } }
    end
  end

  def retry
    pipeline.retry_failed(current_user)

    respond_to do |format|
      format.html do
        redirect_back_or_default default: namespace_project_pipelines_path(project.namespace, project)
      end

      format.json { head :no_content }
    end
  end

  def cancel
    pipeline.cancel_running

    respond_to do |format|
      format.html do
        redirect_back_or_default default: namespace_project_pipelines_path(project.namespace, project)
      end

      format.json { head :no_content }
    end
  end

  def charts
    @charts = {}
    @charts[:week] = Ci::Charts::WeekChart.new(project)
    @charts[:month] = Ci::Charts::MonthChart.new(project)
    @charts[:year] = Ci::Charts::YearChart.new(project)
    @charts[:build_times] = Ci::Charts::BuildTime.new(project)
  end

  private

  def render_show
    respond_to do |format|
      format.html do
        render 'show'
      end
    end
  end

  def create_params
    params.require(:pipeline).permit(:ref)
  end

  def pipeline
    @pipeline ||= project.pipelines.find_by!(id: params[:id]).present(current_user: current_user)
  end

  def commit
    @commit ||= @pipeline.commit
  end
end

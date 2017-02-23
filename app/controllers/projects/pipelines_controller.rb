class Projects::PipelinesController < Projects::ApplicationController
  before_action :pipeline, except: [:index, :new, :create]
  before_action :commit, only: [:show, :builds]
  before_action :authorize_read_pipeline!
  before_action :authorize_create_pipeline!, only: [:new, :create]
  before_action :authorize_update_pipeline!, only: [:retry, :cancel]

  def index
    @scope = params[:scope]
    @pipelines = PipelinesFinder
      .new(project)
      .execute(scope: @scope)
      .page(params[:page])
      .per(30)

    @running_count = PipelinesFinder
      .new(project).execute(scope: 'running').count

    @pending_count = PipelinesFinder
      .new(project).execute(scope: 'pending').count

    @finished_count = PipelinesFinder
      .new(project).execute(scope: 'finished').count

    @pipelines_count = PipelinesFinder
      .new(project).execute.count

    respond_to do |format|
      format.html
      format.json do
        render json: {
          pipelines: PipelineSerializer
            .new(project: @project, user: @current_user)
            .with_pagination(request, response)
            .represent(@pipelines),
          count: {
            all: @pipelines_count,
            running: @running_count,
            pending: @pending_count,
            finished: @finished_count,
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
    respond_to do |format|
      format.html do
        render 'show'
      end
    end
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

    redirect_back_or_default default: namespace_project_pipelines_path(project.namespace, project)
  end

  def cancel
    pipeline.cancel_running

    redirect_back_or_default default: namespace_project_pipelines_path(project.namespace, project)
  end

  private

  def create_params
    params.require(:pipeline).permit(:ref)
  end

  def pipeline
    @pipeline ||= project.pipelines.find_by!(id: params[:id])
  end

  def commit
    @commit ||= @pipeline.commit
  end
end

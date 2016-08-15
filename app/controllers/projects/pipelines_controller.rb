class Projects::PipelinesController < Projects::ApplicationController
  before_action :pipeline, except: [:index, :new, :create]
  before_action :commit, only: [:show]
  before_action :authorize_read_pipeline!
  before_action :authorize_create_pipeline!, only: [:new, :create]
  before_action :authorize_update_pipeline!, only: [:retry, :cancel]

  def index
    @scope = params[:scope]
    all_pipelines = project.pipelines
    @pipelines_count = all_pipelines.count
    @running_or_pending_count = all_pipelines.running_or_pending.count
    @pipelines = PipelinesFinder.new(project).execute(all_pipelines, @scope)
    @pipelines = @pipelines.order(id: :desc).page(params[:page]).per(30)
  end

  def new
    @pipeline = project.pipelines.new(ref: @project.default_branch)
  end

  def create
    @pipeline = Ci::CreatePipelineService.new(project, current_user, create_params).execute(ignore_skip_ci: true, save_on_errors: false)
    unless @pipeline.persisted?
      render 'new'
      return
    end

    redirect_to namespace_project_pipeline_path(project.namespace, project, @pipeline)
  end

  def show
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

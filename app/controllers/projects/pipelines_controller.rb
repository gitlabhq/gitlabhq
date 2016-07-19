class Projects::PipelinesController < Projects::ApplicationController
  before_action :pipeline, except: [:index, :new, :create, :settings, :update_settings]
  before_action :commit, only: [:show]
  before_action :authorize_read_pipeline!
  before_action :authorize_create_pipeline!, only: [:new, :create]
  before_action :authorize_update_pipeline!, only: [:retry, :cancel]
  before_action :authorize_admin_pipeline!, only: [:settings, :update_settings]

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
    @pipeline = Ci::CreatePipelineService.new(project, current_user, create_params).execute
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

  def settings
    @ref = params[:ref] || @project.default_branch || 'master'
    @build_badge = Gitlab::Badge::Build.new(@project, @ref)
  end

  def update_settings
    status = ::Projects::UpdateService.new(@project, current_user, pipelines_settings_params).execute

    respond_to do |format|
      if status
        flash[:notice] = "CI/CD Pipelines settings for '#{@project.name}' was successfully updated."
        format.html do
          redirect_to(
            settings_namespace_project_pipelines_path(@project.namespace, @project),
            notice: "CI/CD Pipelines settings for '#{@project.name}' was successfully updated."
          )
        end
      else
        format.html { render 'settings' }
      end
    end
  end

  private

  def create_params
    params.require(:pipeline).permit(:ref)
  end

  def pipelines_settings_params
    params.require(:project).permit(
      :runners_token, :builds_enabled, :build_allow_git_fetch, :build_timeout_in_minutes, :build_coverage_regex,
      :public_builds
    )
  end

  def pipeline
    @pipeline ||= project.pipelines.find_by!(id: params[:id])
  end

  def commit
    @commit ||= @pipeline.commit
  end
end

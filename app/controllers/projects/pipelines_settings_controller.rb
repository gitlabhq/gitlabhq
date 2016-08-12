class Projects::PipelinesSettingsController < Projects::ApplicationController
  before_action :authorize_admin_pipeline!

  def show
    @ref = params[:ref] || @project.default_branch || 'master'
    @build_badge = Gitlab::Badge::Build.new(@project, @ref).metadata
  end

  def update
    if @project.update_attributes(update_params)
      flash[:notice] = "CI/CD Pipelines settings for '#{@project.name}' were successfully updated."
      redirect_to namespace_project_pipelines_settings_path(@project.namespace, @project)
    else
      render 'index'
    end
  end

  private

  def create_params
    params.require(:pipeline).permit(:ref)
  end

  def update_params
    params.require(:project).permit(
      :runners_token, :builds_enabled, :build_allow_git_fetch, :build_timeout_in_minutes, :build_coverage_regex,
      :public_builds
    )
  end
end

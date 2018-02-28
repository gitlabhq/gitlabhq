class Projects::PipelinesSettingsController < Projects::ApplicationController
  before_action :authorize_admin_pipeline!

  def show
    redirect_to project_settings_ci_cd_path(@project, params: params)
  end

  def update
    if @project.update(update_params)
      flash[:notice] = "Pipelines settings for '#{@project.name}' were successfully updated."
      redirect_to project_settings_ci_cd_path(@project)
    else
      render 'show'
    end
  end

  private

  def update_params
    params.require(:project).permit(
      :runners_token, :builds_enabled, :build_allow_git_fetch,
      :build_timeout_in_minutes, :build_coverage_regex, :public_builds,
      :auto_cancel_pending_pipelines, :ci_config_path,
      auto_devops_attributes: [:id, :domain, :enabled]
    )
  end
end

class Projects::PipelinesSettingsController < Projects::ApplicationController
  before_action :authorize_admin_pipeline!

  def show
    redirect_to project_settings_ci_cd_path(@project, params: params)
  end

  def update
    Projects::UpdateService.new(project, current_user, update_params).tap do |service|
      if service.execute
        flash[:notice] = "Pipelines settings for '#{@project.name}' were successfully updated."

        run_autodevops_pipeline(service)

        redirect_to project_settings_ci_cd_path(@project)
      else
        render 'show'
      end
    end
  end

  private

  def run_autodevops_pipeline(service)
    return unless service.run_auto_devops_pipeline?

    if @project.empty_repo?
      flash[:warning] = "This repository is currently empty. A new Auto DevOps pipeline will be created after a new file has been pushed to a branch."
      return
    end

    CreatePipelineWorker.perform_async(project.id, current_user.id, project.default_branch, :web, ignore_skip_ci: true, save_on_errors: false)
    flash[:success] = "A new Auto DevOps pipeline has been created, go to <a href=\"#{project_pipelines_path(@project)}\">Pipelines page</a> for details".html_safe
  end

  def update_params
    params.require(:project).permit(
      :runners_token, :builds_enabled, :build_allow_git_fetch,
      :build_timeout_human_readable, :build_coverage_regex, :public_builds,
      :auto_cancel_pending_pipelines, :ci_config_path,
      auto_devops_attributes: [:id, :domain, :enabled]
    )
  end
end

class Projects::CiSettingsController < Projects::ApplicationController
  before_action :ci_project
  before_action :authorize_admin_project!

  layout "project_settings"

  def edit
  end

  def update
    if ci_project.update_attributes(project_params)
      Ci::EventService.new.change_project_settings(current_user, ci_project)

      redirect_to edit_namespace_project_ci_settings_path(project.namespace, project), notice: 'Project was successfully updated.'
    else
      render action: "edit"
    end
  end

  def destroy
    ci_project.destroy
    Ci::EventService.new.remove_project(current_user, ci_project)
    project.gitlab_ci_service.update_attributes(active: false)

    redirect_to project_path(project), notice: "CI was disabled for this project"
  end

  protected

  def project_params
    params.require(:project).permit(:path, :timeout, :timeout_in_minutes, :default_ref, :always_build,
                                    :polling_interval, :public, :ssh_url_to_repo, :allow_git_fetch, :email_recipients,
                                    :email_add_pusher, :email_only_broken_builds, :coverage_regex, :shared_runners_enabled, :token,
                                    { variables_attributes: [:id, :key, :value, :_destroy] })
  end
end

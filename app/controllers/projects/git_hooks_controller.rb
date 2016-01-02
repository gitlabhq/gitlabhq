class Projects::GitHooksController < Projects::ApplicationController
  # Authorize
  before_action :authorize_admin_project!

  respond_to :html

  layout "project_settings"

  def index
    project.create_git_hook unless project.git_hook

    @git_hook = project.git_hook
  end

  def update
    @git_hook = project.git_hook
    @git_hook.update_attributes(git_hook_params)

    if @git_hook.valid?
      redirect_to namespace_project_git_hooks_path(@project.namespace, @project)
    else
      render :index
    end
  end

  private

  # Only allow a trusted parameter "white list" through.
  def git_hook_params
    params.require(:git_hook).permit(:deny_delete_tag, :delete_branch_regex,
      :commit_message_regex, :force_push_regex, :author_email_regex, :member_check, :file_name_regex, :max_file_size)
  end
end

class Projects::GitHooksController < Projects::ApplicationController
  # Authorize
  before_filter :authorize_admin_project!

  respond_to :html

  layout "project_settings"

  def index
    project.create_git_hook unless project.git_hook

    @pre_receive_hook = project.git_hook
  end

  def update
    @pre_receive_hook = project.git_hook
    @pre_receive_hook.update_attributes(git_hook_params)

    if @pre_receive_hook.valid?
      redirect_to project_git_hooks_path(@project)
    else
      render :index
    end
  end

  private

  # Only allow a trusted parameter "white list" through.
  def git_hook_params
    params.require(:git_hook).permit(:deny_delete_tag, :delete_branch_regex, :commit_message_regex, :force_push_regex)
  end
end

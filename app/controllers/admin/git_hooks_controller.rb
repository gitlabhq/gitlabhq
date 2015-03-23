class Admin::GitHooksController < Admin::ApplicationController
  before_filter :ensure_hook_exist

  respond_to :html

  def index
  end

  def update
    @git_hook.update_attributes(git_hook_params)

    if @git_hook.valid?
      redirect_to admin_git_hooks_path
    else
      render :index
    end
  end

  private

  # Only allow a trusted parameter "white list" through.
  def git_hook_params
    params.require(:git_hook).permit(:deny_delete_tag, :delete_branch_regex,
      :commit_message_regex, :force_push_regex, :author_email_regex, :member_check, :file_name_regex)
  end

  def ensure_hook_exist
    @git_hook ||= (GitHook.find_by(project_id: nil) || GitHook.create!)
  end
end

class Admin::GitHooksController < Admin::ApplicationController
  before_action :git_hook

  respond_to :html

  def index
  end

  def update
    @git_hook.update_attributes(git_hook_params.merge(is_sample: true))

    if @git_hook.valid?
      redirect_to admin_git_hooks_path
    else
      render :index
    end
  end

  private

  def git_hook_params
    params.require(:git_hook).permit(:deny_delete_tag, :delete_branch_regex,
      :commit_message_regex, :force_push_regex, :author_email_regex, :member_check, :file_name_regex, :max_file_size)
  end

  def git_hook
    @git_hook ||= GitHook.find_or_create_by(is_sample: true)
  end
end

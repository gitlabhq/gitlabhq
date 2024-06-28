# frozen_string_literal: true

class Projects::HookLogsController < Projects::ApplicationController
  before_action :authorize_admin_hook!

  include WebHooks::HookLogActions

  layout 'project_settings'

  private

  def hook
    @hook ||= @project.hooks.find(params[:hook_id])
  end

  def after_retry_redirect_path
    edit_project_hook_path(@project, hook)
  end

  def authorize_admin_hook!
    render_404 unless can?(current_user, :admin_web_hook, project)
  end
end

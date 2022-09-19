# frozen_string_literal: true

class Projects::HookLogsController < Projects::ApplicationController
  before_action :authorize_admin_project!

  include WebHooks::HookLogActions

  layout 'project_settings'

  private

  def hook
    @hook ||= @project.hooks.find(params[:hook_id])
  end

  def after_retry_redirect_path
    edit_project_hook_path(@project, hook)
  end
end

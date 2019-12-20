# frozen_string_literal: true

class Projects::HookLogsController < Projects::ApplicationController
  include HooksExecution

  before_action :authorize_admin_project!

  before_action :hook, only: [:show, :retry]
  before_action :hook_log, only: [:show, :retry]

  respond_to :html

  layout 'project_settings'

  def show
  end

  def retry
    execute_hook
    redirect_to edit_project_hook_path(@project, @hook)
  end

  private

  def execute_hook
    result = hook.execute(hook_log.request_data, hook_log.trigger)
    set_hook_execution_notice(result)
  end

  def hook
    @hook ||= @project.hooks.find(params[:hook_id])
  end

  def hook_log
    @hook_log ||= hook.web_hook_logs.find(params[:id])
  end
end

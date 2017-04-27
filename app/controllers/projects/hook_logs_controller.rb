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
    status, message = hook.execute(hook_log.request_data, hook_log.trigger)

    set_hook_execution_notice(status, message)

    redirect_to edit_namespace_project_hook_path(@project.namespace, @project, @hook)
  end

  private

  def hook
    @hook ||= @project.hooks.find(params[:hook_id])
  end

  def hook_log
    @hook_log ||= hook.web_hook_logs.find(params[:id])
  end
end

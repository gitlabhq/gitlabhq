class Admin::HookLogsController < Admin::ApplicationController
  include HooksExecution

  before_action :hook, only: [:show, :retry]
  before_action :hook_log, only: [:show, :retry]

  respond_to :html

  def show
  end

  def retry
    result = hook.execute(hook_log.request_data, hook_log.trigger)

    set_hook_execution_notice(result)

    redirect_to edit_admin_hook_path(@hook)
  end

  private

  def hook
    @hook ||= SystemHook.find(params[:hook_id])
  end

  def hook_log
    @hook_log ||= hook.web_hook_logs.find(params[:id])
  end
end

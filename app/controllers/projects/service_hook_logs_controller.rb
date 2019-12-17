# frozen_string_literal: true

class Projects::ServiceHookLogsController < Projects::HookLogsController
  before_action :service, only: [:show, :retry]

  def retry
    execute_hook
    redirect_to edit_project_service_path(@project, @service)
  end

  private

  def hook
    @hook ||= service.service_hook
  end

  def service
    @service ||= @project.find_or_initialize_service(params[:service_id])
  end
end

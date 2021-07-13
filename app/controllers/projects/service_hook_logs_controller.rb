# frozen_string_literal: true

class Projects::ServiceHookLogsController < Projects::HookLogsController
  before_action :integration, only: [:show, :retry]

  def retry
    execute_hook
    redirect_to edit_project_service_path(@project, @integration)
  end

  private

  def hook
    @hook ||= integration.service_hook
  end

  def integration
    @integration ||= @project.find_or_initialize_integration(params[:service_id])
  end
end

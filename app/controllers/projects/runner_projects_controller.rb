# frozen_string_literal: true

class Projects::RunnerProjectsController < Projects::ApplicationController
  before_action :authorize_admin_runners!

  layout 'project_settings'

  feature_category :runner_core
  urgency :low

  def create
    @runner = Ci::Runner.find(runner_project_params[:runner_id])

    return head(:forbidden) unless can?(current_user, :assign_runner, @runner)

    path = project_runners_path(project)

    response = ::Ci::Runners::AssignRunnerService.new(@runner, @project, current_user).execute
    if response.success?
      flash[:success] = s_('Runners|Runner assigned to project.')
      redirect_to path
    else
      assign_to_messages = [response.message] + (@runner.errors.messages[:assign_to] || [])
      alert = assign_to_messages.join(', ').presence || 'Failed adding runner to project'

      redirect_to path, alert: alert
    end
  end

  def destroy
    runner_project = project.runner_projects.find(id_param)
    path = project_runners_path(project)

    service_response = ::Ci::Runners::UnassignRunnerService.new(runner_project, current_user).execute

    return redirect_to path, alert: service_response.message, status: :found if service_response.error?

    redirect_to path, status: :found, flash: { success: s_('Runners|Runner unassigned from project.') }
  end

  private

  def runner_project_params
    params.require(:runner_project).permit(:runner_id)
  end

  def id_param
    params.permit(:id)[:id]
  end
end

# frozen_string_literal: true

class Projects::RunnerProjectsController < Projects::ApplicationController
  before_action :authorize_admin_build!

  layout 'project_settings'

  feature_category :continuous_integration

  def create
    @runner = Ci::Runner.find(params[:runner_project][:runner_id])

    return head(403) unless can?(current_user, :assign_runner, @runner)

    path = project_runners_path(project)

    if @runner.assign_to(project, current_user)
      redirect_to path
    else
      assign_to_messages = @runner.errors.messages[:assign_to]
      alert = assign_to_messages&.join(',') || 'Failed adding runner to project'

      redirect_to path, alert: alert
    end
  end

  def destroy
    runner_project = project.runner_projects.find(params[:id])
    runner_project.destroy

    redirect_to project_runners_path(project), status: :found
  end
end

class Projects::RunnerProjectsController < Projects::ApplicationController
  before_action :authorize_admin_build!

  layout 'project_settings'

  def create
    @runner = Ci::Runner.find(params[:runner_project][:runner_id])

    return head(403) unless can?(current_user, :assign_runner, @runner)

    path = project_runners_path(project)
    runner_project = @runner.assign_to(project, current_user)

    if runner_project.persisted?
      redirect_to path
    else
      redirect_to path, alert: 'Failed adding runner to project'
    end
  end

  def destroy
    runner_project = project.runner_projects.find(params[:id])
    runner_project.destroy

    redirect_to project_runners_path(project), status: 302
  end
end

class Projects::RunnerProjectsController < Projects::ApplicationController
  before_action :authorize_admin_build!

  layout 'project_settings'

  def create
    @runner = Ci::Runner.find(params[:runner_project][:runner_id])

    return head(403) unless current_user.ci_authorized_runners.include?(@runner)

    path = runners_path(project)

    if @runner.assign_to(project, current_user)
      redirect_to path
    else
      redirect_to path, alert: 'Failed adding runner to project'
    end
  end

  def destroy
    runner_project = project.runner_projects.find(params[:id])
    runner_project.destroy

    redirect_to runners_path(project)
  end
end

class Admin::RunnerProjectsController < Admin::ApplicationController
  before_action :project, only: [:create]

  def create
    @runner = Ci::Runner.find(params[:runner_project][:runner_id])

    runner_project = @runner.assign_to(@project, current_user)

    if runner_project.persisted?
      redirect_to admin_runner_path(@runner)
    else
      redirect_to admin_runner_path(@runner), alert: 'Failed adding runner to project'
    end
  end

  def destroy
    rp = Ci::RunnerProject.find(params[:id])
    runner = rp.runner
    rp.destroy

    redirect_to admin_runner_path(runner)
  end

  private

  def project
    @project = Project.find_with_namespace(
      [params[:namespace_id], '/', params[:project_id]].join('')
    )
    @project || render_404
  end
end

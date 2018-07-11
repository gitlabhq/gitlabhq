class Admin::RunnerProjectsController < Admin::ApplicationController
  before_action :project, only: [:create]

  def create
    @runner = Ci::Runner.find(params[:runner_project][:runner_id])

    if @runner.assign_to(@project, current_user)
      redirect_to admin_runner_path(@runner)
    else
      redirect_to admin_runner_path(@runner), alert: 'Failed adding runner to project'
    end
  end

  def destroy
    rp = Ci::RunnerProject.find(params[:id])
    runner = rp.runner
    rp.destroy

    redirect_to admin_runner_path(runner), status: :found
  end

  private

  def project
    @project = Project.find_by_full_path(
      [params[:namespace_id], '/', params[:project_id]].join('')
    )
    @project || render_404
  end
end

class Projects::BuildsController < Projects::ApplicationController
  before_action :authorize_read_build!

  def index
    redirect_to project_jobs_path(project)
  end

  def show
    redirect_to project_job_path(project, job)
  end

  def raw
    redirect_to raw_project_job_path(project, job)
  end

  private

  def job
    @job ||= project.builds.find(params[:id])
  end
end

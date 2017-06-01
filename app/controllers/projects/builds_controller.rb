class Projects::BuildsController < Projects::ApplicationController
  before_action :authorize_read_build!

  def index
    redirect_to namespace_project_jobs_path(project.namespace, project)
  end

  def show
    redirect_to namespace_project_job_path(project.namespace, project, job)
  end

  def raw
    redirect_to raw_namespace_project_job_path(project.namespace, project, job)
  end

  private

  def job
    @job ||= project.builds.find(params[:id])
  end
end

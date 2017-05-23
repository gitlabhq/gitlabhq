class Projects::BuildsController < Projects::ApplicationController
  def index
    redirect_to namespace_project_jobs_path(project.namespace, project)
  end

  def show
    redirect_to namespace_project_job_path(project.namespace, project, job)
  end

  def trace
    redirect_to trace_namespace_project_job_path(project.namespace, project, job, format: params[:format])
  end

  def status
    redirect_to status_namespace_project_job_path(project.namespace, project, job, format: params[:format])
  end

  def raw
    redirect_to raw_namespace_project_job_path(project.namespace, project, job)
  end

  private

  def job
    @job ||= project.builds.find(params[:id])
  end
end

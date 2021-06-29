# frozen_string_literal: true

class Projects::BuildArtifactsController < Projects::ApplicationController
  include ExtractsPath
  include RendersBlob

  before_action :authorize_read_build!
  before_action :extract_ref_name_and_path
  before_action :validate_artifacts!, except: [:download]

  feature_category :build_artifacts

  def download
    redirect_to download_project_job_artifacts_path(project, job, params: request.query_parameters)
  end

  def browse
    redirect_to browse_project_job_artifacts_path(project, job, path: params[:path])
  end

  def file
    redirect_to file_project_job_artifacts_path(project, job, path: params[:path])
  end

  def raw
    redirect_to raw_project_job_artifacts_path(project, job, path: params[:path])
  end

  def latest_succeeded
    redirect_to latest_succeeded_project_artifacts_path(project, job, ref_name_and_path: params[:ref_name_and_path], job: params[:job])
  end

  private

  def validate_artifacts!
    render_404 unless job && job.artifacts?
  end

  def extract_ref_name_and_path
    return unless params[:ref_name_and_path]

    @ref_name, @path = extract_ref(params[:ref_name_and_path])
  end

  def job
    @job ||= job_from_id || job_from_ref
  end

  def job_from_id
    project.builds.find_by_id(params[:build_id]) if params[:build_id]
  end

  def job_from_ref
    return unless @ref_name

    project.latest_successful_build_for_ref(params[:job], @ref_name)
  end
end

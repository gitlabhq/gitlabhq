# frozen_string_literal: true

class Projects::BuildArtifactsController < Projects::ApplicationController
  include ExtractsPath

  before_action :authorize_read_build!
  before_action :extract_ref_name_and_path
  before_action :validate_artifacts!, except: [:download]

  feature_category :job_artifacts

  def download
    redirect_to download_project_job_artifacts_path(project, job, params: request.query_parameters)
  end

  def browse
    redirect_to browse_project_job_artifacts_path(project, job, path: artifact_params[:path])
  end

  def file
    redirect_to file_project_job_artifacts_path(project, job, path: artifact_params[:path])
  end

  def raw
    redirect_to raw_project_job_artifacts_path(project, job, path: artifact_params[:path])
  end

  def latest_succeeded
    redirect_to latest_succeeded_project_artifacts_path(
      project,
      job,
      ref_name_and_path: artifact_params[:ref_name_and_path],
      job: artifact_params[:job]
    )
  end

  private

  def artifact_params
    params.permit(:path, :ref_name_and_path, :job, :build_id)
  end

  def validate_artifacts!
    render_404 unless job && job.artifacts?
  end

  def extract_ref_name_and_path
    ref_name_and_path = artifact_params[:ref_name_and_path]
    return unless ref_name_and_path

    ref_extractor = ExtractsRef::RefExtractor.new(@project, {})

    @ref_name, @path = ref_extractor.extract_ref(ref_name_and_path)
  end

  def job
    @job ||= job_from_id || job_from_ref
  end

  def job_from_id
    build_id = artifact_params[:build_id]
    project.builds.find_by_id(build_id) if build_id
  end

  def job_from_ref
    return unless @ref_name

    project.latest_successful_build_for_ref(artifact_params[:job], @ref_name)
  end
end

# frozen_string_literal: true

class Projects::ArtifactsController < Projects::ApplicationController
  include Ci::AuthBuildTrace
  include ExtractsPath
  include RendersBlob
  include SendFileUpload
  include Gitlab::Ci::Artifacts::Logger

  urgency :low, [:browse, :file, :latest_succeeded]

  layout 'project'
  before_action :authorize_read_build!
  before_action :authorize_read_build_trace!, only: [:download]
  before_action :authorize_read_job_artifacts!, only: [:download, :browse, :raw]
  before_action :authorize_update_build!, only: [:keep]
  before_action :authorize_destroy_artifacts!, only: [:destroy]
  before_action :extract_ref_name_and_path
  before_action :validate_artifacts!, except: [:index, :download, :raw, :destroy]
  before_action :entry, only: [:external_file, :file]

  MAX_PER_PAGE = 20

  feature_category :job_artifacts

  def index; end

  def destroy
    notice = if artifact.destroy
               _('Artifact was successfully deleted.')
             else
               _('Artifact could not be deleted.')
             end

    redirect_to project_artifacts_path(@project), status: :see_other, notice: notice
  end

  def download
    return render_404 unless artifact_file

    log_artifacts_filesize(artifact_file.model)
    audit_download(build, artifact_file.filename)

    send_upload(artifact_file, attachment: artifact_file.filename, proxy: params[:proxy])
  end

  def browse
    @path = params[:path]
    directory = @path ? "#{@path}/" : ''
    @entry = build.artifacts_metadata_entry(directory)

    render_404 unless @entry.exists?
  end

  # External files are redirected to Gitlab Pages and might have unsecure content
  # To warn the user about the possible unsecure content, we show a warning page
  # before redirecting the user.
  def external_file
    @blob = @entry.blob
  end

  def file
    blob = @entry.blob
    conditionally_expand_blob(blob)

    if blob.external_link?(build)
      if Gitlab::CurrentSettings.enable_artifact_external_redirect_warning_page
        redirect_to external_file_project_job_artifacts_path(@project, @build, path: params[:path])
      else
        redirect_to blob.external_url(build)
      end
    else
      respond_to do |format|
        format.html do
          render 'file'
        end

        format.json do
          render_blob_json(blob)
        end
      end
    end
  end

  def raw
    return render_404 unless zip_artifact?
    return render_404 unless artifact_file

    path = Gitlab::Ci::Build::Artifacts::Path.new(params[:path])

    send_artifacts_entry(artifact_file, path)
  end

  def keep
    build.keep_artifacts!
    redirect_to project_job_path(project, build)
  end

  def latest_succeeded
    target_path = artifacts_action_path(@path, project, build)

    if target_path
      redirect_to(target_path)
    else
      render_404
    end
  end

  private

  def audit_download(build, filename)
    # overridden in EE
  end

  def extract_ref_name_and_path
    return unless params[:ref_name_and_path]

    ref_extractor = ExtractsRef::RefExtractor.new(@project, {})

    @ref_name, @path = ref_extractor.extract_ref(params[:ref_name_and_path])
  end

  def artifacts_params
    params.permit(:sort)
  end

  def validate_artifacts!
    render_404 unless build&.available_artifacts?
  end

  def build
    @build ||= begin
      build = build_from_id || build_from_sha || build_from_ref
      build&.present(current_user: current_user)
    end
  end

  def artifact
    @artifact ||=
      project.job_artifacts.find(params[:id])
  end

  def build_from_id
    project.builds.find_by_id(params[:job_id]) if params[:job_id]
  end

  def build_from_sha
    return if params[:job].blank?
    return unless @ref_name

    commit = project.commit(@ref_name)
    return unless commit

    project.latest_successful_build_for_sha(params[:job], commit.id)
  end

  def build_from_ref
    return if params[:job].blank?
    return unless @ref_name

    project.latest_successful_build_for_ref(params[:job], @ref_name)
  end

  def job_artifact
    @job_artifact ||= build&.artifact_for_type(params[:file_type] || :archive)
  end

  def artifact_file
    @artifact_file ||= job_artifact&.file
  end

  def zip_artifact?
    types = HashWithIndifferentAccess.new(Enums::Ci::JobArtifact.type_and_format_pairs)
    file_type = params[:file_type] || :archive

    types[file_type] == :zip
  end

  def entry
    @entry = build.artifacts_metadata_entry(params[:path])

    render_404 unless @entry.exists?
  end

  def authorize_read_build_trace!
    return unless params[:file_type] == 'trace'

    super
  end

  def authorize_read_job_artifacts!
    access_denied! unless can?(current_user, :read_job_artifacts, job_artifact)
  end
end

Projects::ArtifactsController.prepend_mod

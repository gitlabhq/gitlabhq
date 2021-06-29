# frozen_string_literal: true

class Projects::ArtifactsController < Projects::ApplicationController
  include ExtractsPath
  include RendersBlob
  include SendFileUpload

  layout 'project'
  before_action :authorize_read_build!
  before_action :authorize_update_build!, only: [:keep]
  before_action :authorize_destroy_artifacts!, only: [:destroy]
  before_action :extract_ref_name_and_path
  before_action :validate_artifacts!, except: [:index, :download, :raw, :destroy]
  before_action :entry, only: [:file]

  MAX_PER_PAGE = 20

  feature_category :build_artifacts

  def index
    # Loading artifacts is very expensive in projects with a lot of artifacts.
    # This feature flag prevents a DOS attack vector.
    # It should be removed only after resolving the underlying performance
    # issues: https://gitlab.com/gitlab-org/gitlab/issues/32281
    return head :no_content unless Feature.enabled?(:artifacts_management_page, @project)

    finder = Ci::JobArtifactsFinder.new(@project, artifacts_params)
    all_artifacts = finder.execute

    @artifacts = all_artifacts.page(params[:page]).per(MAX_PER_PAGE)
    @total_size = all_artifacts.total_size
  end

  def destroy
    notice = if artifact.destroy
               _('Artifact was successfully deleted.')
             else
               _('Artifact could not be deleted.')
             end

    redirect_to project_artifacts_path(@project), status: :see_other, notice: notice
  end

  def download
    return render_404 unless artifacts_file

    send_upload(artifacts_file, attachment: artifacts_file.filename, proxy: params[:proxy])
  end

  def browse
    @path = params[:path]
    directory = @path ? "#{@path}/" : ''
    @entry = build.artifacts_metadata_entry(directory)

    render_404 unless @entry.exists?
  end

  def file
    blob = @entry.blob
    conditionally_expand_blob(blob)

    if blob.external_link?(build)
      redirect_to blob.external_url(@project, build)
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

    path = Gitlab::Ci::Build::Artifacts::Path.new(params[:path])

    send_artifacts_entry(artifacts_file, path)
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

  def extract_ref_name_and_path
    return unless params[:ref_name_and_path]

    @ref_name, @path = extract_ref(params[:ref_name_and_path])
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

  def artifacts_file
    @artifacts_file ||= build&.artifacts_file_for_type(params[:file_type] || :archive)
  end

  def zip_artifact?
    types = HashWithIndifferentAccess.new(Ci::JobArtifact::TYPE_AND_FORMAT_PAIRS)
    file_type = params[:file_type] || :archive

    types[file_type] == :zip
  end

  def entry
    @entry = build.artifacts_metadata_entry(params[:path])

    render_404 unless @entry.exists?
  end
end

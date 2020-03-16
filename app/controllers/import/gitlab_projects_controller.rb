# frozen_string_literal: true

class Import::GitlabProjectsController < Import::BaseController
  include WorkhorseRequest

  before_action :whitelist_query_limiting, only: [:create]
  before_action :verify_gitlab_project_import_enabled

  skip_before_action :verify_authenticity_token, only: [:authorize]
  before_action :verify_workhorse_api!, only: [:authorize]

  def new
    @namespace = Namespace.find(project_params[:namespace_id])
    return render_404 unless current_user.can?(:create_projects, @namespace)

    @path = project_params[:path]
  end

  def create
    unless file_is_valid?
      return redirect_back_or_default(options: { alert: _("You need to upload a GitLab project export archive (ending in .gz).") })
    end

    @project = ::Projects::GitlabProjectsImportService.new(current_user, project_params).execute

    if @project.saved?
      redirect_to(
        project_path(@project),
        notice: _("Project '%{project_name}' is being imported.") % { project_name: @project.name }
      )
    else
      redirect_back_or_default(options: { alert: "Project could not be imported: #{@project.errors.full_messages.join(', ')}" })
    end
  end

  def authorize
    set_workhorse_internal_api_content_type

    authorized = ImportExportUploader.workhorse_authorize(
      has_length: false,
      maximum_size: Gitlab::CurrentSettings.max_attachment_size.megabytes.to_i)

    render json: authorized
  rescue SocketError
    render json: _("Error uploading file"), status: :internal_server_error
  end

  private

  def file_is_valid?
    # TODO: remove the condition and the private method after the WH version including
    # https://gitlab.com/gitlab-org/gitlab-workhorse/-/merge_requests/470
    # is released and GITLAB_WORKHORSE_VERSION is updated accordingly.
    if with_workhorse_upload_acceleration?
      return false unless project_params[:file].is_a?(::UploadedFile)
    else
      return false unless project_params[:file] && project_params[:file].respond_to?(:read)
    end

    filename = project_params[:file].original_filename

    ImportExportUploader::EXTENSION_WHITELIST.include?(File.extname(filename).delete('.'))
  end

  def verify_gitlab_project_import_enabled
    render_404 unless gitlab_project_import_enabled?
  end

  def project_params
    params.permit(
      :path, :namespace_id, :file
    )
  end

  def whitelist_query_limiting
    Gitlab::QueryLimiting.whitelist('https://gitlab.com/gitlab-org/gitlab-foss/issues/42437')
  end

  def with_workhorse_upload_acceleration?
    request.headers[Gitlab::Workhorse::INTERNAL_API_REQUEST_HEADER].present?
  end
end

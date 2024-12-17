# frozen_string_literal: true

class Import::GitlabProjectsController < Import::BaseController
  include WorkhorseAuthorization

  before_action :disable_query_limiting, only: [:create]
  before_action :verify_gitlab_project_import_enabled

  def new
    @namespace = Namespace.find(project_params[:namespace_id])
    return render_404 unless current_user.can?(:import_projects, @namespace)

    @path = project_params[:path]
  end

  def create
    unless file_is_valid?(project_params[:file])
      return redirect_back_or_default(
        options: {
          alert: _("You need to upload a GitLab project export archive (ending in .gz).")
        }
      )
    end

    @project = ::Projects::GitlabProjectsImportService.new(current_user, project_params).execute

    if @project.saved?
      redirect_to(
        project_path(@project),
        notice: _("Project '%{project_name}' is being imported.") % { project_name: @project.name }
      )
    else
      redirect_back_or_default(
        options: {
          alert: "Project could not be imported: #{@project.errors.full_messages.join(', ')}"
        }
      )
    end
  end

  private

  def verify_gitlab_project_import_enabled
    render_404 unless gitlab_project_import_enabled?
  end

  def project_params
    params.permit(
      :name, :path, :namespace_id, :file
    )
  end

  def disable_query_limiting
    Gitlab::QueryLimiting.disable!('https://gitlab.com/gitlab-org/gitlab/-/issues/20823')
  end

  def uploader_class
    ImportExportUploader
  end

  def maximum_size
    Gitlab::CurrentSettings.max_import_size.megabytes
  end
end

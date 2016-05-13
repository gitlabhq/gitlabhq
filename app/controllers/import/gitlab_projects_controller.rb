class Import::GitlabProjectsController < Import::BaseController
  before_action :verify_gitlab_project_import_enabled
  before_action :verify_project_and_namespace_access

  rescue_from OAuth::Error, with: :gitlab_project_unauthorized

  def new
    @namespace_id = project_params[:namespace_id]
    @path = project_params[:path]
  end

  def create
    @project = Project.create_from_import_job(current_user_id: current_user.id,
                                              tmp_file: File.expand_path(params[:file].path),
                                              namespace_id: project_params[:namespace_id],
                                              project_path: project_params[:path])

    redirect_to dashboard_projects_path
  end

  private

  def verify_project_and_namespace_access
    unless namespace_access? && project_access?
      render_403
    end
  end

  def project_access?
    can?(current_user, :admin_project, @project)
  end

  def namespace_access?
    current_user.can?(:create_projects, Namespace.find(project_params[:namespace_id]))
  end

  def verify_gitlab_project_import_enabled
    render_404 unless gitlab_project_import_enabled?
  end

  def project_params
    params.permit(
      :path, :namespace_id,
    )
  end
end

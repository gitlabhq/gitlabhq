class Import::GitlabProjectsController < Import::BaseController
  before_action :verify_gitlab_project_import_enabled
  before_action :verify_project_and_namespace_access

  def new
    @namespace_id = project_params[:namespace_id]
    @path = project_params[:path]
  end

  def create
    unless file_is_valid?
      return redirect_back_or_default(options: { alert: "You need to upload a GitLab project export archive." })
    end

    @project = Gitlab::ImportExport::ProjectCreator.new(project_params[:namespace_id],
                                                        current_user,
                                                        File.expand_path(project_params[:file].path),
                                                        project_params[:path]).execute

    if @project.saved?
      redirect_to(
        project_path(@project),
        notice: "Project '#{@project.name}' is being imported."
      )
    else
      redirect_to(
        new_project_path,
        alert: "Project could not be exported: #{@project.errors.full_messages.join(', ')}"
      )
    end
  end

  private

  def file_is_valid?
    project_params[:file].respond_to?(:read) && project_params[:file].content_type == 'application/x-gzip'
  end

  def verify_project_and_namespace_access
    unless namespace_access?
      render_403
    end
  end

  def namespace_access?
    can?(current_user, :create_projects, Namespace.find(project_params[:namespace_id]))
  end

  def verify_gitlab_project_import_enabled
    render_404 unless gitlab_project_import_enabled?
  end

  def project_params
    params.permit(
      :path, :namespace_id, :file
    )
  end
end

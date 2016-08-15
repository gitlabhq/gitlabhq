class Import::GitlabProjectsController < Import::BaseController
  before_action :verify_gitlab_project_import_enabled
  before_action :authenticate_admin!

  def new
    @namespace_id = project_params[:namespace_id]
    @namespace_name = Namespace.find(project_params[:namespace_id]).name
    @path = project_params[:path]
  end

  def create
    unless file_is_valid?
      return redirect_back_or_default(options: { alert: "You need to upload a GitLab project export archive." })
    end

    imported_file = project_params[:file].path + "-import"

    FileUtils.copy_entry(project_params[:file].path, imported_file)

    @project = Gitlab::ImportExport::ProjectCreator.new(project_params[:namespace_id],
                                                        current_user,
                                                        File.expand_path(imported_file),
                                                        project_params[:path]).execute

    if @project.saved?
      redirect_to(
        project_path(@project),
        notice: "Project '#{@project.name}' is being imported."
      )
    else
      redirect_to(
        new_import_gitlab_project_path,
        alert: "Project could not be imported: #{@project.errors.full_messages.join(', ')}"
      )
    end
  end

  private

  def file_is_valid?
    project_params[:file] && project_params[:file].respond_to?(:read)
  end

  def verify_gitlab_project_import_enabled
    render_404 unless gitlab_project_import_enabled?
  end

  def project_params
    params.permit(
      :path, :namespace_id, :file
    )
  end

  def authenticate_admin!
    render_404 unless current_user.is_admin?
  end
end

class Import::GitlabProjectsController < Import::BaseController
  before_action :whitelist_query_limiting, only: [:create]
  before_action :verify_gitlab_project_import_enabled

  def new
    @namespace = Namespace.find(project_params[:namespace_id])
    return render_404 unless current_user.can?(:create_projects, @namespace)

    @path = project_params[:path]
  end

  def create
    unless file_is_valid?
      return redirect_back_or_default(options: { alert: "You need to upload a GitLab project export archive." })
    end

    @project = ::Projects::GitlabProjectsImportService.new(current_user, project_params).execute

    if @project.saved?
      redirect_to(
        project_path(@project),
        notice: "Project '#{@project.name}' is being imported."
      )
    else
      redirect_back_or_default(options: { alert: "Project could not be imported: #{@project.errors.full_messages.join(', ')}" })
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

  def whitelist_query_limiting
    Gitlab::QueryLimiting.whitelist('https://gitlab.com/gitlab-org/gitlab-ce/issues/42437')
  end
end

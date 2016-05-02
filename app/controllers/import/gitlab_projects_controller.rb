class Import::GitlabProjectsController < Import::BaseController
  before_action :verify_gitlab_project_import_enabled
  #before_action :gitlab_project_auth, except: :callback

  rescue_from OAuth::Error, with: :gitlab_project_unauthorized

  #TODO permissions stuff

  def new
    @namespace_id = project_params[:namespace_id]
    @path = project_params[:path]
  end

  def status

  end

  def jobs
    jobs = current_user.created_projects.where(import_type: "gitlab_project").to_json(only: [:id, :import_status])
    render json: jobs
  end

  def create
    # TODO verify access to namespace and path
    file = params[:file]
    namespace_id = project_params[:namespace_id]
    path = project_params[:path]

    repo_owner = current_user.username
    @target_namespace = params[:new_namespace].presence || repo_owner

    @project = Project.create_from_import_job(current_user_id: current_user.id,
                                              tmp_file: File.expand_path(file.path),
                                              namespace_id: namespace_id,
                                              project_path: path)

    redirect_to status_import_gitlab_project_path
  end

  private

  def verify_gitlab_project_import_enabled
    render_404 unless gitlab_project_import_enabled?
  end

  def project_params
    params.permit(
      :path, :namespace_id,
    )
  end
end

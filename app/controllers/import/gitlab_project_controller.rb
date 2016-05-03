class Import::GitlabProjectController < Import::BaseController
  before_action :verify_gitlab_project_import_enabled
  before_action :gitlab_project_auth, except: :callback

  rescue_from OAuth::Error, with: :gitlab_project_unauthorized

  #TODO permissions stuff

  def callback

    redirect_to status_import_gitlab_project_url
  end

  def status
    @repos = client.projects
    @incompatible_repos = client.incompatible_projects

    @already_added_projects = current_user.created_projects.where(import_type: "gitlab_project")
    already_added_projects_names = @already_added_projects.pluck(:import_source)

    @repos.to_a.reject!{ |repo| already_added_projects_names.include? "#{repo["owner"]}/#{repo["slug"]}" }
  end

  def jobs
    jobs = current_user.created_projects.where(import_type: "gitlab_project").to_json(only: [:id, :import_status])
    render json: jobs
  end

  def create
    @file = params[:file]

    repo_owner = current_user.username
    @target_namespace = params[:new_namespace].presence || repo_owner

    # namespace = get_or_create_namespace || (render and return)

    @project = Gitlab::ImportExport::ImportService.execute(archive_file: file, owner: repo_owner)
  end

  private

  def verify_gitlab_project_import_enabled
    render_404 unless gitlab_project_import_enabled?
  end
end

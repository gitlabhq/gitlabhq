class Import::GitoriousController < Import::BaseController
  before_action :verify_gitorious_import_enabled

  def new
    redirect_to client.authorize_url(callback_import_gitorious_url)
  end

  def callback
    session[:gitorious_repos] = params[:repos]
    redirect_to status_import_gitorious_path
  end

  def status
    @repos = client.repos

    @already_added_projects = current_user.created_projects.where(import_type: "gitorious")
    already_added_projects_names = @already_added_projects.pluck(:import_source)

    @repos.reject! { |repo| already_added_projects_names.include? repo.full_name }
  end

  def jobs
    jobs = current_user.created_projects.where(import_type: "gitorious").to_json(only: [:id, :import_status])
    render json: jobs
  end

  def create
    @repo_id = params[:repo_id]
    repo = client.repo(@repo_id)
    @target_namespace = params[:new_namespace].presence || repo.namespace
    @project_name = repo.name

    namespace = get_or_create_namespace || (render and return)

    @project = Gitlab::GitoriousImport::ProjectCreator.new(repo, namespace, current_user).execute
  end

  private

  def client
    @client ||= Gitlab::GitoriousImport::Client.new(session[:gitorious_repos])
  end

  def verify_gitorious_import_enabled
    render_404 unless gitorious_import_enabled?
  end

end

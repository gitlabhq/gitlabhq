class Import::GogsController < Import::BaseController
  before_action :verify_gogs_import_enabled
  before_action :gogs_auth, only: [:status, :jobs, :create]

  rescue_from Octokit::Unauthorized, with: :gogs_unauthorized

  helper_method :logged_in_with_gogs?

  def new
    if session[:gogs_access_token]
      redirect_to status_import_gogs_url
    end
  end

  def personal_access_token
    session[:gogs_access_token] = params[:personal_access_token]
    session[:gogs_host_url] = params[:gogs_host_url]
    redirect_to status_import_gogs_url
  end

  def status
    @repos = client.repos
    @already_added_projects = current_user.created_projects.where(import_type: "gogs")
    already_added_projects_names = @already_added_projects.pluck(:import_source)

    @gogs_root_url = session[:gogs_host_url]

    @repos.reject!{ |repo| already_added_projects_names.include? repo.full_name }
  end

  def jobs
    jobs = current_user.created_projects.where(import_type: "gogs").to_json(only: [:id, :import_status])
    render json: jobs
  end

  def create
    @repo_id = params[:repo_id].to_i
    repo = client.repo(@repo_id)
    @project_name = params[:new_name].presence || repo.name
    namespace_path = params[:target_namespace].presence || current_user.namespace_path
    @target_namespace = find_or_create_namespace(namespace_path, current_user.namespace_path)

    if current_user.can?(:create_projects, @target_namespace)
      @project = Gitlab::GithubImport::ProjectCreator.new(repo, @project_name, @target_namespace, current_user, access_params, type: 'gogs').execute
    else
      render 'unauthorized'
    end
  end

  private

  def client
    @client ||= Gitlab::GithubImport::Client.new(session[:gogs_access_token], host: session[:gogs_host_url], api_version: 'v1')
  end

  def verify_gogs_import_enabled
    render_404 unless gogs_import_enabled?
  end

  def gogs_auth
    if session[:gogs_access_token].blank? || session[:gogs_host_url].blank?
      redirect_to new_import_gogs_url,
        alert: 'You need to specify both an Access Token and a Host URL.'
    end
  end

  def gogs_unauthorized
    session[:gogs_access_token] = nil
    redirect_to new_import_gogs_url,
      alert: 'Access denied to your Gogs account.'
  end

  def access_params
    { github_access_token: session[:gogs_access_token] }
  end
end

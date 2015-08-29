class Import::GithubController < Import::BaseController
  before_action :verify_github_import_enabled
  before_action :github_auth, except: :callback

  rescue_from Octokit::Unauthorized, with: :github_unauthorized

  def callback
    session[:github_access_token] = client.get_token(params[:code])
    redirect_to status_import_github_url
  end

  def status
    @repos = client.repos
    client.orgs.each do |org|
      @repos += client.org_repos(org.login)
    end

    @already_added_projects = current_user.created_projects.where(import_type: "github")
    already_added_projects_names = @already_added_projects.pluck(:import_source)

    @repos.reject!{ |repo| already_added_projects_names.include? repo.full_name }
  end

  def jobs
    jobs = current_user.created_projects.where(import_type: "github").to_json(only: [:id, :import_status])
    render json: jobs
  end

  def create
    @repo_id = params[:repo_id].to_i
    repo = client.repo(@repo_id)
    @project_name = repo.name

    repo_owner = repo.owner.login
    repo_owner = current_user.username if repo_owner == client.user.login
    @target_namespace = params[:new_namespace].presence || repo_owner

    namespace = get_or_create_namespace || (render and return)

    @project = Gitlab::GithubImport::ProjectCreator.new(repo, namespace, current_user, access_params).execute
  end

  private

  def client
    @client ||= Gitlab::GithubImport::Client.new(session[:github_access_token])
  end

  def verify_github_import_enabled
    not_found! unless github_import_enabled?
  end

  def github_auth
    if session[:github_access_token].blank?
      go_to_github_for_permissions
    end
  end

  def go_to_github_for_permissions
    redirect_to client.authorize_url(callback_import_github_url)
  end

  def github_unauthorized
    go_to_github_for_permissions
  end

  private

  def access_params
    { github_access_token: session[:github_access_token] }
  end
end

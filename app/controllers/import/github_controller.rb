class Import::GithubController < Import::BaseController
  before_action :verify_github_import_enabled
  before_action :github_auth, only: [:status, :jobs, :create]

  rescue_from Octokit::Unauthorized, with: :github_unauthorized

  helper_method :logged_in_with_github?

  def new
    if logged_in_with_github?
      go_to_github_for_permissions
    elsif session[:github_access_token]
      redirect_to status_import_github_url
    end
  end

  def callback
    session[:github_access_token] = client.get_token(params[:code])
    redirect_to status_import_github_url
  end

  def personal_access_token
    session[:github_access_token] = params[:personal_access_token]
    redirect_to status_import_github_url
  end

  def status
    @repos = client.repos
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
    @target_namespace = find_or_create_namespace(repo.owner.login, client.user.login)

    if current_user.can?(:create_projects, @target_namespace)
      @project = Gitlab::GithubImport::ProjectCreator.new(repo, @target_namespace, current_user, access_params).execute
    else
      render 'unauthorized'
    end
  end

  private

  def client
    @client ||= Gitlab::GithubImport::Client.new(session[:github_access_token])
  end

  def verify_github_import_enabled
    render_404 unless github_import_enabled?
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
    session[:github_access_token] = nil
    redirect_to new_import_github_url,
      alert: 'Access denied to your GitHub account.'
  end

  def logged_in_with_github?
    current_user.identities.exists?(provider: 'github')
  end

  def access_params
    { github_access_token: session[:github_access_token] }
  end
end

class Import::BitbucketController < Import::BaseController
  before_action :verify_bitbucket_import_enabled
  before_action :bitbucket_auth, except: :callback

  rescue_from OAuth::Error, with: :bitbucket_unauthorized
  rescue_from Bitbucket::Error::Unauthorized, with: :bitbucket_unauthorized

  def callback
    response = client.auth_code.get_token(params[:code], redirect_uri: callback_import_bitbucket_url)

    session[:bitbucket_token]         = response.token
    session[:bitbucket_expires_at]    = response.expires_at
    session[:bitbucket_expires_in]    = response.expires_in
    session[:bitbucket_refresh_token] = response.refresh_token

    redirect_to status_import_bitbucket_url
  end

  def status
    client = Bitbucket::Client.new(credentials)
    repos  = client.repos

    @repos = repos.select(&:valid?)
    @incompatible_repos = repos.reject(&:valid?)

    @already_added_projects = current_user.created_projects.where(import_type: 'bitbucket')
    already_added_projects_names = @already_added_projects.pluck(:import_source)

    @repos.to_a.reject! { |repo| already_added_projects_names.include?(repo.full_name) }
  end

  def jobs
    render json: current_user.created_projects
                             .where(import_type: 'bitbucket')
                             .to_json(only: [:id, :import_status])
  end

  def create
    client = Bitbucket::Client.new(credentials)

    @repo_id = params[:repo_id].to_s
    name = @repo_id.to_s.gsub('___', '/')
    repo = client.repo(name)
    @project_name = repo.name

    repo_owner = repo.owner
    repo_owner = current_user.username if repo_owner == client.user.username
    @target_namespace = params[:new_namespace].presence || repo_owner

    namespace = find_or_create_namespace(target_namespace_name, repo_owner)

    if current_user.can?(:create_projects, @target_namespace)
      @project = Gitlab::BitbucketImport::ProjectCreator.new(repo, namespace, current_user, credentials).execute
    else
      render 'unauthorized'
    end
  end

  private

  def client
    @client ||= OAuth2::Client.new(provider.app_id, provider.app_secret, options)
  end

  def provider
    Gitlab.config.omniauth.providers.find { |provider| provider.name == 'bitbucket' }
  end

  def options
    OmniAuth::Strategies::Bitbucket.default_options[:client_options].deep_symbolize_keys
  end

  def verify_bitbucket_import_enabled
    render_404 unless bitbucket_import_enabled?
  end

  def bitbucket_auth
    go_to_bitbucket_for_permissions if session[:bitbucket_token].blank?
  end

  def go_to_bitbucket_for_permissions
    redirect_to client.auth_code.authorize_url(redirect_uri: callback_import_bitbucket_url)
  end

  def bitbucket_unauthorized
    go_to_bitbucket_for_permissions
  end

  def credentials
    {
      token: session[:bitbucket_token],
      expires_at: session[:bitbucket_expires_at],
      expires_in: session[:bitbucket_expires_in],
      refresh_token: session[:bitbucket_refresh_token]
    }
  end
end

class Import::GiteaController < Import::GithubController
  def new
    if session[:access_token].present? && session[:host_url].present?
      redirect_to status_import_url
    end
  end

  def personal_access_token
    session[:host_url] = params[:gitea_host_url]
    super
  end

  def status
    @gitea_root_url = session[:host_url]
    super
  end

  private

  # Overriden methods
  def provider
    :gitea
  end

  # Gitea is not yet an OAuth provider
  # See https://github.com/go-gitea/gitea/issues/27
  def logged_in_with_provider?
    false
  end

  def provider_auth
    if session[:access_token].blank? || session[:host_url].blank?
      redirect_to new_import_gitea_url,
        alert: 'You need to specify both an Access Token and a Host URL.'
    end
  end

  def client_options
    { host: session[:host_url], api_version: 'v1' }
  end
end

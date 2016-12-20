class Import::GiteaController < Import::GithubController
  def new
    if session[access_token_key].present? && session[host_key].present?
      redirect_to status_import_url
    end
  end

  def personal_access_token
    session[host_key] = params[host_key]
    super
  end

  def status
    @gitea_host_url = session[host_key]
    super
  end

  private

  def host_key
    :"#{provider}_host_url"
  end

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
    if session[access_token_key].blank? || session[host_key].blank?
      redirect_to new_import_gitea_url,
        alert: 'You need to specify both an Access Token and a Host URL.'
    end
  end

  def client_options
    { host: session[host_key], api_version: 'v1' }
  end
end

namespace :gitlab do
  namespace :container_registry do
    desc "GitLab | Container Registry | Configure"
    task configure: :gitlab_environment do
      registry_config = Gitlab.config.registry

      unless registry_config.enabled && registry_config.api_url.presence
        raise 'Registry is not enabled or registry api url is not present.'
      end

      warn_user_is_not_gitlab

      url = registry_config.api_url
      # registry_info will query the /v2 route of the registry API. This route
      # requires authentication, but not authorization (the response has no body,
      # only headers that show the version of the registry). There is no
      # associated user when running this rake, so we need to generate a valid
      # JWT token with no access permissions to authenticate as a trusted client.
      token = Auth::ContainerRegistryAuthenticationService.access_token([], [])
      client = ContainerRegistry::Client.new(url, token: token)
      info = client.registry_info

      Gitlab::CurrentSettings.update!(
        container_registry_vendor: info[:vendor] || '',
        container_registry_version: info[:version] || '',
        container_registry_features: info[:features] || []
      )
    end
  end
end

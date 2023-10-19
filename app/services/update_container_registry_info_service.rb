# frozen_string_literal: true

class UpdateContainerRegistryInfoService
  def execute
    registry_config = Gitlab.config.registry
    return unless registry_config.enabled && registry_config.api_url.presence

    # registry_info will query the /v2 route of the registry API. This route
    # requires authentication, but not authorization (the response has no body,
    # only headers that show the version of the registry). There might be no
    # associated user when running this (e.g. from a rake task or a cron job),
    # so we need to generate a valid JWT token with no access permissions to
    # authenticate as a trusted client.
    token = Auth::ContainerRegistryAuthenticationService.access_token({})
    client = ContainerRegistry::Client.new(registry_config.api_url, token: token)
    info = client.registry_info

    gitlab_api_client = ContainerRegistry::GitlabApiClient.new(registry_config.api_url, token: token)
    if gitlab_api_client.supports_gitlab_api?
      info[:features] ||= []
      info[:features] << ContainerRegistry::GitlabApiClient::REGISTRY_GITLAB_V1_API_FEATURE
    end

    Gitlab::CurrentSettings.update!(
      container_registry_vendor: info[:vendor] || '',
      container_registry_version: info[:version] || '',
      container_registry_features: info[:features] || [],
      container_registry_db_enabled: info[:db_enabled] || false
    )
  end
end

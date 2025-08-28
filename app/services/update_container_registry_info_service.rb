# frozen_string_literal: true

class UpdateContainerRegistryInfoService
  def execute
    info = fetch_registry_info

    return unless info

    Gitlab::CurrentSettings.update!(
      container_registry_vendor: info[:vendor] || '',
      container_registry_version: info[:version] || '',
      container_registry_features: info[:features] || [],
      container_registry_db_enabled: info[:db_enabled] || false
    )
  end

  private

  def fetch_registry_info
    return fetch_registry_info_from_v2 unless ContainerRegistry::GitlabApiClient.supports_gitlab_api?

    info = ContainerRegistry::GitlabApiClient.statistics.merge({ vendor: 'gitlab' })
    info[:features] ||= []
    info[:features] << ContainerRegistry::GitlabApiClient::REGISTRY_GITLAB_V1_API_FEATURE

    info
  end

  def fetch_registry_info_from_v2
    # if the gitlab API is not available, registry_info will query the /v2 route of the registry API. This route
    # requires authentication, but not authorization (the response has no body,
    # only headers that show the version of the registry). There might be no
    # associated user when running this (e.g. from a rake task or a cron job),
    # so we need to generate a valid JWT token with no access permissions to
    # authenticate as a trusted client.

    registry_config = Gitlab.config.registry
    return unless registry_config.enabled && registry_config.api_url.presence

    token = Auth::ContainerRegistryAuthenticationService.access_token({})
    client = ContainerRegistry::Client.new(registry_config.api_url, token: token)
    client.registry_info
  end
end

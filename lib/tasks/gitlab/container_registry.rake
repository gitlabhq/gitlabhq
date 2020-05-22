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
      client = ContainerRegistry::Client.new(url)
      info = client.registry_info

      Gitlab::CurrentSettings.update!(
        container_registry_vendor: info[:vendor] || '',
        container_registry_version: info[:version] || '',
        container_registry_features: info[:features] || []
      )
    end
  end
end

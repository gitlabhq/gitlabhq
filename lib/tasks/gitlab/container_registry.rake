# frozen_string_literal: true

namespace :gitlab do
  namespace :container_registry do
    desc "GitLab | Container Registry | Configure"
    task configure: :gitlab_environment do
      configure
    end

    def configure
      registry_config = Gitlab.config.registry

      unless registry_config.enabled && registry_config.api_url.presence
        puts "Registry is not enabled or registry api url is not present.".color(:yellow)
        return
      end

      warn_user_is_not_gitlab

      UpdateContainerRegistryInfoService.new.execute
    end
  end
end

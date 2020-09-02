# frozen_string_literal: true

module ContainerRegistryHelper
  def limit_delete_tags_service?
    Feature.enabled?(:container_registry_expiration_policies_throttling) &&
      ContainerRegistry::Client.supports_tag_delete?
  end
end

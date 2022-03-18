# frozen_string_literal: true

module ContainerRegistryHelper
  def container_registry_expiration_policies_throttling?
    Feature.enabled?(:container_registry_expiration_policies_throttling, default_enabled: :yaml)
  end

  def container_repository_gid_prefix
    "gid://#{GlobalID.app}/#{ContainerRepository.name}/"
  end
end

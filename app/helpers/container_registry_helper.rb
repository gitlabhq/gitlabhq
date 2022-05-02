# frozen_string_literal: true

module ContainerRegistryHelper
  def container_repository_gid_prefix
    "gid://#{GlobalID.app}/#{ContainerRepository.name}/"
  end
end

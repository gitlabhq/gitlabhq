# frozen_string_literal: true

module Types
  module PermissionTypes
    class ContainerRepositoryTag < BasePermissionType
      graphql_name 'ContainerRepositoryTagPermissions'

      ability_field :destroy_container_image_tag,
        name: 'destroy_container_repository_tag',
        resolver_method: :destroy_container_image_tag
    end
  end
end

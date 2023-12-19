# frozen_string_literal: true

module Types
  module PermissionTypes
    class ContainerRepository < BasePermissionType
      graphql_name 'ContainerRepositoryPermissions'

      ability_field :destroy_container_image,
        name: 'destroy_container_repository',
        resolver_method: :destroy_container_image
    end
  end
end

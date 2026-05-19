# frozen_string_literal: true

module Types
  module ContainerRegistry
    class ContainerRepositoryImagePlatformType < BaseObject
      graphql_name 'ContainerRepositoryImagePlatform'
      description 'Description of the target platform for an image.'
      authorize :read_container_image

      field :architecture, GraphQL::Types::String, null: true,
        description: 'CPU architecture of the platform.'
      field :os, GraphQL::Types::String, null: true,
        description: 'Operating system of the platform.'
      field :os_version, GraphQL::Types::String, null: true,
        description: 'Operating system version, typically used for Windows images.'
      field :variant, GraphQL::Types::String, null: true,
        description: 'CPU variant of the platform.'
    end
  end
end

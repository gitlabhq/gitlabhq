# frozen_string_literal: true

module Types
  module ContainerRegistry
    class ContainerRepositoryImageManifestType < BaseObject
      graphql_name 'ContainerRepositoryImageManifest'
      description 'A manifest describing a reference to an image.'
      authorize :read_container_image

      field :digest, GraphQL::Types::String, null: true,
        description: 'Digest of the manifest.'
      field :media_type, GraphQL::Types::String, null: true,
        description: 'Media type of the manifest.'
      field :platform, Types::ContainerRegistry::ContainerRepositoryImagePlatformType, null: true,
        description: 'Platform specifier for the image reference.'
      field :size, GraphQL::Types::BigInt, null: true,
        description: 'Size of the manifest in bytes.'
    end
  end
end

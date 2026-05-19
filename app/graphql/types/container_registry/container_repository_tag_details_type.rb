# frozen_string_literal: true

module Types
  module ContainerRegistry
    class ContainerRepositoryTagDetailsType < BaseObject
      graphql_name 'ContainerRepositoryTagDetails'
      description 'Details of a tag within a container repository'
      authorize :read_container_image

      field :created_at, Types::TimeType, null: true, description: 'Timestamp when the tag was created.'
      field :digest, GraphQL::Types::String, null: true, description: 'Digest of the tag.'
      field :location, GraphQL::Types::String, null: false, description: 'URL of the tag.'
      field :manifests,
        [Types::ContainerRegistry::ContainerRepositoryImageManifestType],
        null: true,
        description: 'Manifests of the index tag. Null for non-index tags.'
      field :media_type, GraphQL::Types::String, null: true, description: 'Media type of the tag.'
      field :name, GraphQL::Types::String, null: false, description: 'Name of the tag.'
      field :path, GraphQL::Types::String, null: false, description: 'Path of the tag.'
      field :platform,
        Types::ContainerRegistry::ContainerRepositoryImagePlatformType,
        null: true,
        description: 'Platform of the image tag. Null for index tags.'
      field :published_at, Types::TimeType, null: true, description: 'Timestamp when the tag was published.'
      field :total_size, GraphQL::Types::BigInt, null: true, description: 'Size of the tag.'
    end
  end
end

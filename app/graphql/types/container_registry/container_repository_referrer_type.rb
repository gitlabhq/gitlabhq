# frozen_string_literal: true

module Types
  module ContainerRegistry
    class ContainerRepositoryReferrerType < BaseObject
      graphql_name 'ContainerRepositoryReferrer'

      description 'A referrer for a container repository tag'

      authorize :read_container_image

      expose_permissions Types::PermissionTypes::ContainerRepositoryTag

      field :artifact_type, GraphQL::Types::String, description: 'Artifact type of the referrer.'
      field :digest, GraphQL::Types::String, description: 'Digest of the referrer.'
    end
  end
end

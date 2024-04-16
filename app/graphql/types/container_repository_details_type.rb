# frozen_string_literal: true

module Types
  class ContainerRepositoryDetailsType < Types::ContainerRepositoryType
    graphql_name 'ContainerRepositoryDetails'

    description 'Details of a container repository'

    authorize :read_container_image

    field :tags,
          Types::ContainerRepositoryTagType.connection_type,
          null: true,
          description: 'Tags of the container repository.',
          max_page_size: 20,
          resolver: Resolvers::ContainerRepositoryTagsResolver,
          connection_extension: Gitlab::Graphql::Extensions::ExternallyPaginatedArrayExtension

    field :manifest, GraphQL::Types::String,
          null: true,
          description: 'An image manifest from the container repository.' do
            argument :reference, GraphQL::Types::String,
              required: true,
              description: 'Tag name or digest of the manifest.'
          end

    field :size,
          GraphQL::Types::Float,
          null: true,
          description: 'Deduplicated size of the image repository in bytes. This is only available on GitLab.com for repositories created after `2021-11-04`.'

    def can_delete
      Ability.allowed?(current_user, :destroy_container_image, object)
    end

    def size
      handling_errors { object.size }
    end

    def manifest(reference:)
      handling_errors { object.image_manifest(reference) }
    end

    private

    def handling_errors
      yield
    rescue Faraday::Error
      raise ::Gitlab::Graphql::Errors::ResourceNotAvailable, "Can't connect to the Container Registry. If this error persists, please review the troubleshooting documentation."
    end
  end
end

# frozen_string_literal: true

module Types
  module ContainerRegistry
    class ContainerRepositoryDetailsType < Types::ContainerRegistry::ContainerRepositoryType # rubocop:disable Graphql/AuthorizeTypes -- authorization is inherited from the parent: ContainerRepositoryType
      graphql_name 'ContainerRepositoryDetails'

      include Gitlab::Graphql::Authorize::AuthorizeResource

      description 'Details of a container repository'

      field :tags,
        Types::ContainerRegistry::ContainerRepositoryTagType.connection_type,
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
        description:
          'Deduplicated size of the image repository in bytes. ' \
          'This is only available on GitLab.com for repositories created after `2021-11-04`.'

      field :last_published_at,
        Types::TimeType,
        null: true,
        description:
          'Timestamp when a repository tag was last created or updated. ' \
          'Only present for repositories that had tags created or updated after GitLab 16.11.'

      def size
        handling_errors { object.size }
      end

      def last_published_at
        handling_errors { object.last_published_at }
      end

      def manifest(reference:)
        handling_errors do
          manifest = object.image_manifest(reference)
          manifest.as_json if manifest
        end
      end

      private

      def handling_errors
        yield
      rescue Faraday::Error
        raise_resource_not_available_error!(
          "Can't connect to the Container Registry. " \
            'If this error persists, please review the troubleshooting documentation.'
        )
      end
    end
  end
end

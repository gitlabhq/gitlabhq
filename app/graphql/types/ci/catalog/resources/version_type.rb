# frozen_string_literal: true

module Types
  module Ci
    module Catalog
      module Resources
        # rubocop: disable Graphql/AuthorizeTypes -- Authorization is handled by Ci::Catalog::Resources::VersionsFinder in the resolver.
        class VersionType < BaseObject
          graphql_name 'CiCatalogResourceVersion'

          connection_type_class Types::CountableConnectionType

          field :id, ::Types::GlobalIDType[::Ci::Catalog::Resources::Version], null: false,
            description: 'Global ID of the version.',
            alpha: { milestone: '16.7' }

          field :created_at, Types::TimeType, null: true, description: 'Timestamp of when the version was created.',
            alpha: { milestone: '16.7' }

          field :released_at, Types::TimeType, null: true, description: 'Timestamp of when the version was released.',
            alpha: { milestone: '16.7' }

          field :tag_name, GraphQL::Types::String, null: true, method: :name,
            description: 'Deprecated in 16.8. Use name.',
            alpha: { milestone: '16.7' }

          field :name, GraphQL::Types::String, null: true,
            description: 'Name that uniquely identifies the version within the catalog resource.',
            alpha: { milestone: '16.8' }

          field :tag_path, GraphQL::Types::String, null: true, method: :path,
            description: 'Deprecated in 16.8. Use path.',
            alpha: { milestone: '16.7' }

          field :path, GraphQL::Types::String, null: true,
            description: 'Relative web path to the version.',
            alpha: { milestone: '16.8' }

          field :author, Types::UserType, null: true, description: 'User that created the version.',
            alpha: { milestone: '16.7' }

          field :commit, Types::CommitType, null: true, complexity: 10, calls_gitaly: true,
            description: 'Commit associated with the version.',
            alpha: { milestone: '16.7' }

          field :components, Types::Ci::Catalog::Resources::ComponentType.connection_type, null: true,
            description: 'Components belonging to the catalog resource.',
            alpha: { milestone: '16.7' }

          def author
            Gitlab::Graphql::Loaders::BatchModelLoader.new(User, object.author_id).find
          end
        end
        # rubocop: enable Graphql/AuthorizeTypes
      end
    end
  end
end

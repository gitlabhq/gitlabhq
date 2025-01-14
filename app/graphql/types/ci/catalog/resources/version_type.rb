# frozen_string_literal: true

module Types
  module Ci
    module Catalog
      module Resources
        # rubocop: disable Graphql/AuthorizeTypes -- Authorization is handled by Ci::Catalog::Resources
        class VersionType < BaseObject
          graphql_name 'CiCatalogResourceVersion'

          connection_type_class Types::CountableConnectionType

          field :id, ::Types::GlobalIDType[::Ci::Catalog::Resources::Version], null: false,
            description: 'Global ID of the version.'

          field :created_at, Types::TimeType, null: true, description: 'Timestamp of when the version was created.'

          field :released_at, Types::TimeType, null: true, description: 'Timestamp of when the version was released.',
            experiment: { milestone: '16.7' }

          field :name, GraphQL::Types::String, null: true,
            description: 'Name that uniquely identifies the version within the catalog resource.'

          field :path, GraphQL::Types::String, null: true,
            description: 'Relative web path to the version.'

          field :author, Types::UserType, null: true, description: 'User that created the version.'

          field :commit, Types::Repositories::CommitType, null: true, complexity: 10, calls_gitaly: true,
            description: 'Commit associated with the version.'

          field :components, Types::Ci::Catalog::Resources::ComponentType.connection_type, null: true,
            description: 'Components belonging to the catalog resource.'

          field :readme, GraphQL::Types::String, null: true, calls_gitaly: true,
            description: 'Readme data.' do
              extension ::Gitlab::Graphql::Limit::FieldCallCount, limit: 1
            end

          markdown_field :readme_html, null: true

          def readme_html_resolver
            ctx = context.to_h.dup.merge(project: object.project)
            ::MarkupHelper.markdown(object.readme, ctx, { requested_path: object.project.path })
          end

          def author
            Gitlab::Graphql::Loaders::BatchModelLoader.new(User, object.author_id).find
          end
        end
        # rubocop: enable Graphql/AuthorizeTypes
      end
    end
  end
end

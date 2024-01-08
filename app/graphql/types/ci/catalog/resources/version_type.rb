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

          field :name, GraphQL::Types::String, null: true,
            description: 'Name that uniquely identifies the version within the catalog resource.',
            alpha: { milestone: '16.8' }

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

          field :readme_html, GraphQL::Types::String, null: true, calls_gitaly: true,
            description: 'GitLab Flavored Markdown rendering of README.md. This field ' \
                         'can only be resolved for one version in any single request.',
            alpha: { milestone: '16.8' } do
              extension ::Gitlab::Graphql::Limit::FieldCallCount, limit: 1 # To avoid N+1 calls to Gitaly
            end

          def author
            Gitlab::Graphql::Loaders::BatchModelLoader.new(User, object.author_id).find
          end

          def readme_html
            return unless Ability.allowed?(current_user, :read_code, object.project)

            markdown_context = context.to_h.dup.merge(project: object.project)
            ::MarkupHelper.markdown(object.readme&.data, markdown_context)
          end
        end
        # rubocop: enable Graphql/AuthorizeTypes
      end
    end
  end
end

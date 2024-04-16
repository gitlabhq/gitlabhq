# frozen_string_literal: true

module Types
  module Ci
    module Catalog
      # rubocop: disable Graphql/AuthorizeTypes
      class ResourceType < BaseObject
        graphql_name 'CiCatalogResource'

        connection_type_class Types::CountableConnectionType

        field :open_issues_count, GraphQL::Types::Int, null: false,
          description: 'Count of open issues that belong to the the catalog resource.',
          alpha: { milestone: '16.3' }

        field :open_merge_requests_count, GraphQL::Types::Int, null: false,
          description: 'Count of open merge requests that belong to the the catalog resource.',
          alpha: { milestone: '16.3' }

        field :id, GraphQL::Types::ID, null: false, description: 'ID of the catalog resource.',
          alpha: { milestone: '15.11' }

        field :name, GraphQL::Types::String, null: true, description: 'Name of the catalog resource.',
          alpha: { milestone: '15.11' }

        field :description, GraphQL::Types::String, null: true, description: 'Description of the catalog resource.',
          alpha: { milestone: '15.11' }

        field :icon, GraphQL::Types::String, null: true, description: 'Icon for the catalog resource.',
          method: :avatar_path, alpha: { milestone: '15.11' }

        field :full_path, GraphQL::Types::String, null: true, description: 'Full project path of the catalog resource.',
          alpha: { milestone: '16.11' }

        field :web_path, GraphQL::Types::String, null: true, description: 'Web path of the catalog resource.',
          alpha: { milestone: '16.1' }

        field :versions, Types::Ci::Catalog::Resources::VersionType.connection_type, null: true,
          description: 'Versions of the catalog resource. This field can only be ' \
                       'resolved for one catalog resource in any single request.',
          resolver: Resolvers::Ci::Catalog::Resources::VersionsResolver,
          alpha: { milestone: '16.2' }

        field :verification_level, Types::Ci::Catalog::Resources::Components::VerificationLevelEnum, null: true,
          description: 'Verification level of the catalog resource.',
          alpha: { milestone: '16.9' }

        field :latest_released_at, Types::TimeType, null: true,
          description: "Release date of the catalog resource's latest version.",
          alpha: { milestone: '16.5' }

        field :star_count, GraphQL::Types::Int, null: false,
          description: 'Number of times the catalog resource has been starred.',
          alpha: { milestone: '16.1' }

        field :starrers_path, GraphQL::Types::String, null: true,
          description: 'Relative path to the starrers page for the catalog resource project.',
          alpha: { milestone: '16.10' }

        def open_issues_count
          BatchLoader::GraphQL.wrap(object.project.open_issues_count)
        end

        def open_merge_requests_count
          BatchLoader::GraphQL.wrap(object.project.open_merge_requests_count)
        end

        def web_path
          ::Gitlab::Routing.url_helpers.project_path(object.project)
        end

        def readme_html_resolver
          markdown_context = context.to_h.dup.merge(project: object.project)
          ::MarkupHelper.markdown(object.project.repository.readme&.data, markdown_context)
        end

        def starrers_path
          Gitlab::Routing.url_helpers.project_starrers_path(object.project)
        end
      end
      # rubocop: enable Graphql/AuthorizeTypes
    end
  end
end

# frozen_string_literal: true

module Types
  module Namespaces
    # This type returns columns added by the `Namespace#with_statistics` scope.

    # `ResolvesGroups#resolve_with_lookahead` detects if the `project_statistics`
    # field is requested and passes the `with_statistics` argument to `GroupsFinder`
    # which then calls `Namespace#with_statistics`.
    class ProjectStatisticsType < BaseObject
      graphql_name 'NamespaceProjectStatistics'

      authorize :read_statistics

      field :build_artifacts_size, GraphQL::Types::Float, null: true,
        description: 'Build artifacts size of the project in bytes.',
        extras: [:graphql_name],
        resolver_method: :try_field
      field :lfs_objects_size,
        GraphQL::Types::Float,
        null: true,
        description: 'Large File Storage (LFS) object size of the project in bytes.',
        extras: [:graphql_name],
        resolver_method: :try_field
      field :packages_size, GraphQL::Types::Float, null: true,
        description: 'Packages size of the project in bytes.',
        extras: [:graphql_name],
        resolver_method: :try_field
      field :pipeline_artifacts_size, GraphQL::Types::Float, null: true,
        description: 'CI/CD Pipeline artifacts size in bytes.',
        extras: [:graphql_name],
        resolver_method: :try_field
      field :repository_size, GraphQL::Types::Float, null: true,
        description: 'Repository size of the project in bytes.',
        extras: [:graphql_name],
        resolver_method: :try_field
      field :snippets_size, GraphQL::Types::Float, null: true,
        description: 'Snippets size of the project in bytes.',
        extras: [:graphql_name],
        resolver_method: :try_field
      field :storage_size, GraphQL::Types::Float, null: true,
        description: 'Storage size of the project in bytes.',
        extras: [:graphql_name],
        resolver_method: :try_field
      field :uploads_size, GraphQL::Types::Float, null: true,
        description: 'Uploads size of the project in bytes.',
        extras: [:graphql_name],
        resolver_method: :try_field
      field :wiki_size, GraphQL::Types::Float, null: true,
        description: 'Wiki size of the project in bytes.',
        extras: [:graphql_name],
        resolver_method: :try_field

      def try_field(graphql_name:)
        object.try(graphql_name.underscore)
      end
    end
  end
end

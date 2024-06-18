# frozen_string_literal: true
# rubocop: disable Graphql/ResolverType

module Resolvers
  class GroupPackagesResolver < PackagesBaseResolver
    # The GraphQL type is defined in the extended class

    extension ::Gitlab::Graphql::Limit::FieldCallCount, limit: 1

    argument :sort, Types::Packages::PackageGroupSortEnum,
      description: 'Sort packages by the criteria.',
      required: false,
      default_value: :created_desc

    GROUP_SORT_TO_PARAMS_MAP = SORT_TO_PARAMS_MAP.merge({
      project_path_desc: { order_by: 'project_path', sort: 'desc' },
      project_path_asc: { order_by: 'project_path', sort: 'asc' }
    }).freeze

    def resolve(sort:, **filters)
      return unless packages_available?

      params = filters.merge(GROUP_SORT_TO_PARAMS_MAP.fetch(sort))
      params[:preload_pipelines] = false

      ::Packages::GroupPackagesFinder.new(current_user, object, params).execute
    end
  end
end
# rubocop: enable Graphql/ResolverType

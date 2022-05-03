# frozen_string_literal: true
# rubocop: disable Graphql/ResolverType

module Resolvers
  class GroupPackagesResolver < PackagesBaseResolver
    # The GraphQL type is defined in the extended class

    argument :sort, Types::Packages::PackageGroupSortEnum,
      description: 'Sort packages by this criteria.',
      required: false,
      default_value: :created_desc

    GROUP_SORT_TO_PARAMS_MAP = SORT_TO_PARAMS_MAP.merge({
      project_path_desc: { order_by: 'project_path', sort: 'desc' },
      project_path_asc: { order_by: 'project_path', sort: 'asc' }
    }).freeze

    def ready?(**args)
      # TODO remove when cleaning up packages_graphql_pipelines_resolver
      # https://gitlab.com/gitlab-org/gitlab/-/issues/358432
      context.scoped_set!(:packages_access_level, :group)

      context[self.class] ||= { executions: 0 }
      context[self.class][:executions] += 1
      raise GraphQL::ExecutionError, "Packages can be requested only for one group at a time" if context[self.class][:executions] > 1

      super
    end

    def resolve(sort:, **filters)
      return unless packages_available?

      params = filters.merge(GROUP_SORT_TO_PARAMS_MAP.fetch(sort))
      params[:preload_pipelines] = false

      ::Packages::GroupPackagesFinder.new(current_user, object, params).execute
    end
  end
end
# rubocop: enable Graphql/ResolverType

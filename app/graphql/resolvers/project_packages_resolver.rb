# frozen_string_literal: true
# rubocop: disable Graphql/ResolverType

module Resolvers
  class ProjectPackagesResolver < PackagesBaseResolver
    # The GraphQL type is defined in the extended class

    # TODO remove when cleaning up packages_graphql_pipelines_resolver
    # https://gitlab.com/gitlab-org/gitlab/-/issues/358432
    def ready?(**args)
      context.scoped_set!(:packages_access_level, :project)

      super
    end

    def resolve(sort:, **filters)
      return unless packages_available?

      params = filters.merge(SORT_TO_PARAMS_MAP.fetch(sort))
      params[:preload_pipelines] = false

      ::Packages::PackagesFinder.new(object, params).execute
    end
  end
end
# rubocop: enable Graphql/ResolverType

# frozen_string_literal: true
# rubocop: disable Graphql/ResolverType

module Resolvers
  class ProjectPackagesResolver < PackagesBaseResolver
    # The GraphQL type is defined in the extended class

    def resolve(sort:, **filters)
      return unless packages_available?

      params = filters.merge(SORT_TO_PARAMS_MAP.fetch(sort))
      params[:preload_pipelines] = false

      ::Packages::PackagesFinder.new(object, params).execute
    end
  end
end
# rubocop: enable Graphql/ResolverType

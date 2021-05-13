# frozen_string_literal: true
# rubocop: disable Graphql/ResolverType

module Resolvers
  class ProjectPackagesResolver < PackagesBaseResolver
    # The GraphQL type is defined in the extended class

    def resolve(sort:, **filters)
      return unless packages_available?

      ::Packages::PackagesFinder.new(object, filters.merge(SORT_TO_PARAMS_MAP.fetch(sort))).execute
    end
  end
end
# rubocop: enable Graphql/ResolverType

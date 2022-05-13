# frozen_string_literal: true

module Types
  module Packages
    class PackageType < Types::Packages::PackageBaseType
      graphql_name 'Package'
      description 'Represents a package with pipelines in the Package Registry'

      authorize :read_package

      field :pipelines,
            resolver: Resolvers::PackagePipelinesResolver,
            description: <<-DESC
              Pipelines that built the package. Max page size #{Resolvers::PackagePipelinesResolver::MAX_PAGE_SIZE}.
            DESC
    end
  end
end

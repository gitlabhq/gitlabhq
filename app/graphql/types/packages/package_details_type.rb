# frozen_string_literal: true

module Types
  module Packages
    class PackageDetailsType < PackageType
      graphql_name 'PackageDetailsType'
      description 'Represents a package details in the Package Registry. Note that this type is in beta and susceptible to changes'
      authorize :read_package

      field :versions, ::Types::Packages::PackageType.connection_type, null: true,
        description: 'Other versions of the package.'

      field :package_files, Types::Packages::PackageFileType.connection_type, null: true, description: 'Package files.'

      field :dependency_links, Types::Packages::PackageDependencyLinkType.connection_type, null: true, description: 'Dependency link.'

      # this is an override of Types::Packages::PackageType.pipelines
      # in order to use a custom resolver: Resolvers::PackagePipelinesResolver
      field :pipelines,
            resolver: Resolvers::PackagePipelinesResolver,
            description: 'Pipelines that built the package.',
            deprecated: { reason: 'Due to scalability concerns, this field is going to be removed', milestone: '14.6' }

      def versions
        object.versions
      end

      def package_files
        if Feature.enabled?(:packages_installable_package_files)
          object.installable_package_files
        else
          object.package_files
        end
      end
    end
  end
end

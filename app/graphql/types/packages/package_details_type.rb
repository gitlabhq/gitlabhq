# frozen_string_literal: true

module Types
  module Packages
    class PackageDetailsType < PackageType
      graphql_name 'PackageDetailsType'
      description 'Represents a package details in the Package Registry. Note that this type is in beta and susceptible to changes'
      authorize :read_package

      field :versions, ::Types::Packages::PackageType.connection_type, null: true,
        description: 'The other versions of the package.'

      field :package_files, Types::Packages::PackageFileType.connection_type, null: true, description: 'Package files.'

      def versions
        object.versions
      end
    end
  end
end

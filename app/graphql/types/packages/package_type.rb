# frozen_string_literal: true

module Types
  module Packages
    class PackageType < PackageWithoutVersionsType
      graphql_name 'Package'
      description 'Represents a package in the Package Registry'
      authorize :read_package

      field :versions, ::Types::Packages::PackageWithoutVersionsType.connection_type, null: true,
        description: 'The other versions of the package.'
    end
  end
end

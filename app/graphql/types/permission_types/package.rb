# frozen_string_literal: true

module Types
  module PermissionTypes
    class Package < BasePermissionType
      graphql_name 'PackagePermissions'

      ability_field :destroy_package,
        description: 'If `true`, the user can perform `destroy_package` on this resource'
    end
  end
end

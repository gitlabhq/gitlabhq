# frozen_string_literal: true

module Types
  module Packages
    module Protection
      class RuleType < ::Types::BaseObject
        graphql_name 'PackagesProtectionRule'
        description 'A packages protection rule designed to protect packages ' \
                    'from being pushed by users with a certain access level.'

        authorize :admin_package

        field :id,
          ::Types::GlobalIDType[::Packages::Protection::Rule],
          null: false,
          description: 'ID of the package protection rule.'

        field :package_name_pattern,
          GraphQL::Types::String,
          null: false,
          description:
            'Package name protected by the protection rule. For example `@my-scope/my-package-*`. ' \
            'Wildcard character `*` allowed.'

        field :package_type,
          Types::Packages::Protection::RulePackageTypeEnum,
          null: false,
          description: 'Package type protected by the protection rule. For example `NPM`.'

        field :push_protected_up_to_access_level,
          Types::Packages::Protection::RuleAccessLevelEnum,
          null: false,
          description:
            'Max GitLab access level unable to push a package. For example `DEVELOPER`, `MAINTAINER`, `OWNER`.'
      end
    end
  end
end

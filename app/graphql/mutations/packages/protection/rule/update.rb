# frozen_string_literal: true

module Mutations
  module Packages
    module Protection
      module Rule
        class Update < ::Mutations::BaseMutation
          graphql_name 'UpdatePackagesProtectionRule'
          description 'Updates a package protection rule to restrict access to project packages. ' \
                      'You can prevent users without certain permissions from altering packages. ' \
                      'Available only when feature flag `packages_protected_packages` is enabled.'

          authorize :admin_package

          argument :id,
            ::Types::GlobalIDType[::Packages::Protection::Rule],
            required: true,
            description: 'Global ID of the package protection rule to be updated.'

          argument :package_name_pattern,
            GraphQL::Types::String,
            required: false,
            validates: { allow_blank: false },
            description:
            'Package name protected by the protection rule. For example, `@my-scope/my-package-*`. ' \
            'Wildcard character `*` allowed.'

          argument :package_type,
            Types::Packages::Protection::RulePackageTypeEnum,
            required: false,
            validates: { allow_blank: false },
            description: 'Package type protected by the protection rule. For example, `NPM`.'

          argument :push_protected_up_to_access_level,
            Types::Packages::Protection::RuleAccessLevelEnum,
            required: false,
            validates: { allow_blank: false },
            description:
              'Maximum GitLab access level unable to push a package. For example, `DEVELOPER`, `MAINTAINER`, `OWNER`.'

          field :package_protection_rule,
            Types::Packages::Protection::RuleType,
            null: true,
            description: 'Packages protection rule after mutation.'

          def resolve(id:, **kwargs)
            package_protection_rule = authorized_find!(id: id)

            if Feature.disabled?(:packages_protected_packages, package_protection_rule.project)
              raise_resource_not_available_error!("'packages_protected_packages' feature flag is disabled")
            end

            response = ::Packages::Protection::UpdateRuleService.new(package_protection_rule,
              current_user: current_user, params: kwargs).execute

            { package_protection_rule: response.payload[:package_protection_rule], errors: response.errors }
          end
        end
      end
    end
  end
end

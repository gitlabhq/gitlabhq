# frozen_string_literal: true

module Mutations
  module Packages
    module Protection
      module Rule
        class Create < ::Mutations::BaseMutation
          graphql_name 'CreatePackagesProtectionRule'
          description 'Creates a protection rule to restrict access to project packages. ' \
                      'Available only when feature flag `packages_protected_packages` is enabled.'

          include FindsProject

          authorize :admin_package

          argument :project_path,
            GraphQL::Types::ID,
            required: true,
            description: 'Full path of the project where a protection rule is located.'

          argument :package_name_pattern,
            GraphQL::Types::String,
            required: true,
            description:
              'Package name protected by the protection rule. For example `@my-scope/my-package-*`. ' \
              'Wildcard character `*` allowed.'

          argument :package_type,
            Types::Packages::Protection::RulePackageTypeEnum,
            required: true,
            description: 'Package type protected by the protection rule. For example `NPM`.'

          argument :push_protected_up_to_access_level,
            Types::Packages::Protection::RuleAccessLevelEnum,
            required: true,
            description:
            'Max GitLab access level unable to push a package. For example `DEVELOPER`, `MAINTAINER`, `OWNER`.'

          field :package_protection_rule,
            Types::Packages::Protection::RuleType,
            null: true,
            description: 'Packages protection rule after mutation.'

          def resolve(project_path:, **kwargs)
            project = authorized_find!(project_path)

            if Feature.disabled?(:packages_protected_packages, project)
              raise_resource_not_available_error!("'packages_protected_packages' feature flag is disabled")
            end

            response = ::Packages::Protection::CreateRuleService.new(project: project, current_user: current_user,
              params: kwargs).execute

            { package_protection_rule: response.payload[:package_protection_rule], errors: response.errors }
          end
        end
      end
    end
  end
end

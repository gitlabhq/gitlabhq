# frozen_string_literal: true

module Mutations
  module Packages
    module Protection
      module Rule
        class Create < ::Mutations::BaseMutation
          graphql_name 'CreatePackagesProtectionRule'
          description 'Creates a protection rule to restrict access to project packages.'

          include FindsProject

          authorize :admin_package

          argument :project_path,
            GraphQL::Types::ID,
            required: true,
            description: 'Full path of the project where a protection rule is located.'

          argument :package_name_pattern,
            GraphQL::Types::String,
            required: true,
            description: copy_field_description(Types::Packages::Protection::RuleType, :package_name_pattern)

          argument :package_type,
            Types::Packages::Protection::RulePackageTypeEnum,
            required: true,
            description: copy_field_description(Types::Packages::Protection::RuleType, :package_type)

          argument :minimum_access_level_for_push,
            Types::Packages::Protection::RuleAccessLevelEnum,
            required: true,
            description: copy_field_description(Types::Packages::Protection::RuleType, :minimum_access_level_for_push)

          field :package_protection_rule,
            Types::Packages::Protection::RuleType,
            null: true,
            description: 'Packages protection rule after mutation.'

          def resolve(project_path:, **kwargs)
            project = authorized_find!(project_path)

            response = ::Packages::Protection::CreateRuleService.new(project: project, current_user: current_user,
              params: kwargs).execute

            { package_protection_rule: response.payload[:package_protection_rule], errors: response.errors }
          end
        end
      end
    end
  end
end

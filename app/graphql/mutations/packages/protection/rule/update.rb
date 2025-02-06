# frozen_string_literal: true

module Mutations
  module Packages
    module Protection
      module Rule
        class Update < ::Mutations::BaseMutation
          graphql_name 'UpdatePackagesProtectionRule'
          description 'Updates a package protection rule to restrict access to project packages. ' \
            'You can prevent users without certain permissions from altering packages.'

          authorize :admin_package

          argument :id,
            ::Types::GlobalIDType[::Packages::Protection::Rule],
            required: true,
            description: 'Global ID of the package protection rule to be updated.'

          argument :package_name_pattern,
            GraphQL::Types::String,
            required: false,
            validates: { allow_blank: false },
            description: copy_field_description(Types::Packages::Protection::RuleType, :package_name_pattern)

          argument :package_type,
            Types::Packages::Protection::RulePackageTypeEnum,
            required: false,
            validates: { allow_blank: false },
            description: copy_field_description(Types::Packages::Protection::RuleType, :package_type)

          argument :minimum_access_level_for_push,
            Types::Packages::Protection::RuleAccessLevelEnum,
            required: false,
            validates: { allow_blank: false },
            description: copy_field_description(Types::Packages::Protection::RuleType, :minimum_access_level_for_push)

          field :package_protection_rule,
            Types::Packages::Protection::RuleType,
            null: true,
            description: 'Packages protection rule after mutation.'

          def resolve(id:, **kwargs)
            package_protection_rule = authorized_find!(id: id)

            response = ::Packages::Protection::UpdateRuleService.new(package_protection_rule,
              current_user: current_user, params: kwargs).execute

            { package_protection_rule: response.payload[:package_protection_rule], errors: response.errors }
          end
        end
      end
    end
  end
end

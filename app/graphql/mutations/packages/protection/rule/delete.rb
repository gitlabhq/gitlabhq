# frozen_string_literal: true

module Mutations
  module Packages
    module Protection
      module Rule
        class Delete < ::Mutations::BaseMutation
          graphql_name 'DeletePackagesProtectionRule'
          description 'Deletes a protection rule for packages.'

          authorize :admin_package

          argument :id,
            ::Types::GlobalIDType[::Packages::Protection::Rule],
            required: true,
            description: 'Global ID of the package protection rule to delete.'

          field :package_protection_rule,
            Types::Packages::Protection::RuleType,
            null: true,
            description: 'Packages protection rule that was deleted successfully.'

          def resolve(id:, **_kwargs)
            package_protection_rule = authorized_find!(id: id)

            response = ::Packages::Protection::DeleteRuleService.new(package_protection_rule,
              current_user: current_user).execute

            { package_protection_rule: response.payload[:package_protection_rule], errors: response.errors }
          end
        end
      end
    end
  end
end

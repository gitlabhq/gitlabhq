# frozen_string_literal: true

module Mutations
  module Terraform
    module StateProtectionRule
      class Delete < ::Mutations::BaseMutation
        graphql_name 'DeleteTerraformStateProtectionRule'
        description 'Deletes a protection rule for a Terraform state backend.'

        authorize :delete_terraform_state_protection_rule
        authorize_granular_token permissions: :delete_terraform_state_protection_rule,
          boundary_argument: :id, boundary: :project, boundary_type: :project

        argument :id,
          ::Types::GlobalIDType[::Terraform::StateProtectionRule],
          required: true,
          description: 'Global ID of the Terraform state protection rule to delete.'

        field :terraform_state_protection_rule,
          Types::Terraform::StateProtectionRuleType,
          null: true,
          experiment: { milestone: '19.1' },
          description: 'Terraform state protection rule that was deleted.'

        def resolve(id:, **_kwargs)
          protection_rule = authorized_find!(id: id)

          if Feature.disabled?(:protected_terraform_states, protection_rule.project)
            raise_resource_not_available_error! '`protected_terraform_states` feature flag is disabled.'
          end

          response = ::Terraform::StateProtectionRules::DeleteRuleService.new(
            protection_rule,
            current_user: current_user
          ).execute

          {
            terraform_state_protection_rule: response.payload[:terraform_state_protection_rule],
            errors: response.errors
          }
        end
      end
    end
  end
end

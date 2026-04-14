# frozen_string_literal: true

module Mutations
  module Terraform
    module StateProtectionRule
      class Update < ::Mutations::BaseMutation
        graphql_name 'UpdateTerraformStateProtectionRule'
        description 'Updates a protection rule for a Terraform state backend.'

        authorize :admin_terraform_state

        argument :id,
          ::Types::GlobalIDType[::Terraform::StateProtectionRule],
          required: true,
          description: 'Global ID of the Terraform state protection rule to update.'

        argument :state_name,
          GraphQL::Types::String,
          required: false,
          validates: { allow_blank: false },
          experiment: { milestone: '18.11' },
          description: copy_field_description(
            Types::Terraform::StateProtectionRuleType, :state_name
          )

        argument :minimum_access_level_for_write,
          Types::Terraform::StateProtectionRuleAccessLevelEnum,
          required: false,
          experiment: { milestone: '18.11' },
          description: copy_field_description(
            Types::Terraform::StateProtectionRuleType, :minimum_access_level_for_write
          )

        argument :allowed_from,
          Types::Terraform::StateProtectionRuleAllowedFromEnum,
          required: false,
          experiment: { milestone: '18.11' },
          description: copy_field_description(
            Types::Terraform::StateProtectionRuleType, :allowed_from
          )

        field :terraform_state_protection_rule,
          Types::Terraform::StateProtectionRuleType,
          null: true,
          experiment: { milestone: '18.11' },
          description: 'Terraform state protection rule after mutation.'

        def resolve(id:, **kwargs)
          protection_rule = authorized_find!(id: id)

          if Feature.disabled?(:protected_terraform_states, protection_rule.project)
            raise_resource_not_available_error! '`protected_terraform_states` feature flag is disabled.'
          end

          response = ::Terraform::StateProtectionRules::UpdateRuleService.new(
            protection_rule,
            current_user: current_user,
            params: kwargs
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

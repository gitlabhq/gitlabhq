# frozen_string_literal: true

module Mutations
  module Terraform
    module StateProtectionRule
      class Create < ::Mutations::BaseMutation
        graphql_name 'CreateTerraformStateProtectionRule'
        description 'Creates a protection rule for a Terraform state backend.'

        include FindsProject

        authorize :create_terraform_state_protection_rule
        authorize_granular_token permissions: :create_terraform_state_protection_rule,
          boundary_argument: :project_path,
          boundary_type: :project

        argument :project_path,
          GraphQL::Types::ID,
          required: true,
          description: 'Full path of the project where the protection rule is located.'

        argument :state_name,
          GraphQL::Types::String,
          required: true,
          description: copy_field_description(
            Types::Terraform::StateProtectionRuleType, :state_name
          )

        argument :minimum_access_level_for_write,
          Types::Terraform::StateProtectionRuleAccessLevelEnum,
          required: true,
          description: copy_field_description(
            Types::Terraform::StateProtectionRuleType, :minimum_access_level_for_write
          )

        argument :allowed_from,
          Types::Terraform::StateProtectionRuleAllowedFromEnum,
          required: false,
          default_value: 'anywhere',
          experiment: { milestone: '19.1' },
          description: copy_field_description(
            Types::Terraform::StateProtectionRuleType, :allowed_from
          )

        field :terraform_state_protection_rule,
          Types::Terraform::StateProtectionRuleType,
          null: true,
          experiment: { milestone: '19.1' },
          description: 'Terraform state protection rule after mutation.'

        def resolve(project_path:, **kwargs)
          project = authorized_find!(project_path)

          if Feature.disabled?(:protected_terraform_states, project)
            raise_resource_not_available_error! '`protected_terraform_states` feature flag is disabled.'
          end

          response = ::Terraform::StateProtectionRules::CreateRuleService.new(
            project: project,
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

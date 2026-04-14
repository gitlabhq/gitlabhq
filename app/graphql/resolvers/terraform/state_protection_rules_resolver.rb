# frozen_string_literal: true

module Resolvers
  module Terraform
    class StateProtectionRulesResolver < BaseResolver
      type Types::Terraform::StateProtectionRuleType.connection_type, null: true

      alias_method :project, :object

      def resolve(**_args)
        return ::Terraform::StateProtectionRule.none if Feature.disabled?(:protected_terraform_states, project)

        project.terraform_state_protection_rules
      end
    end
  end
end

# frozen_string_literal: true

module Types
  module Terraform
    class StateProtectionRuleAccessLevelEnum < BaseEnum
      graphql_name 'TerraformStateProtectionRuleAccessLevel'
      description 'Access level for Terraform state protection rule write operations.'

      ::Terraform::StateProtectionRule.minimum_access_level_for_writes.each_key do |access_level_key|
        value access_level_key.upcase,
          value: access_level_key.to_s,
          experiment: { milestone: '18.11' },
          description: "#{access_level_key.to_s.capitalize} access."
      end
    end
  end
end

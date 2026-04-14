# frozen_string_literal: true

module Types
  module Terraform
    class StateProtectionRuleAllowedFromEnum < BaseEnum
      graphql_name 'TerraformStateProtectionRuleAllowedFrom'
      description 'Source restriction for Terraform state protection rule write operations.'

      ::Terraform::StateProtectionRule.allowed_froms.each_key do |allowed_from_key|
        value allowed_from_key.upcase,
          value: allowed_from_key.to_s,
          experiment: { milestone: '18.11' },
          description: "#{allowed_from_key.to_s.humanize}."
      end
    end
  end
end

# frozen_string_literal: true

module Types
  module ContainerRegistry
    module Protection
      class RuleAccessLevelEnum < BaseEnum
        graphql_name 'ContainerRegistryProtectionRuleAccessLevel'
        description 'Access level of a container registry protection rule resource'

        ::ContainerRegistry::Protection::Rule.push_protected_up_to_access_levels.each_key do |access_level_key|
          value access_level_key.upcase, value: access_level_key.to_s,
            description: "#{access_level_key.capitalize} access."
        end
      end
    end
  end
end

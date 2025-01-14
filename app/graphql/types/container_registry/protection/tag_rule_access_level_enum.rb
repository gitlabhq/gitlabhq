# frozen_string_literal: true

module Types
  module ContainerRegistry
    module Protection
      class TagRuleAccessLevelEnum < BaseEnum
        graphql_name 'ContainerProtectionTagRuleAccessLevel'
        description 'Access level of a container registry tag protection rule resource'

        ::ContainerRegistry::Protection::TagRule::ACCESS_LEVELS.each_key do |access_level_key|
          access_level_key = access_level_key.to_s

          value access_level_key.upcase,
            value: access_level_key,
            experiment: { milestone: '17.8' },
            description: "#{access_level_key.capitalize} access."
        end
      end
    end
  end
end

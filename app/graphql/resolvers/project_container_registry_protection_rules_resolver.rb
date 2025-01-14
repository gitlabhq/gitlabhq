# frozen_string_literal: true

module Resolvers
  class ProjectContainerRegistryProtectionRulesResolver < BaseResolver
    type Types::ContainerRegistry::Protection::RuleType.connection_type, null: true

    alias_method :project, :object

    def resolve(**_args)
      project.container_registry_protection_rules
    end
  end
end

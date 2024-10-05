# frozen_string_literal: true

module Resolvers
  class ProjectContainerRegistryProtectionRulesResolver < BaseResolver
    type Types::ContainerRegistry::Protection::RuleType.connection_type, null: true

    alias_method :project, :object

    def resolve(**_args)
      return [] if Feature.disabled?(:container_registry_protected_containers, project.root_ancestor)

      project.container_registry_protection_rules
    end
  end
end

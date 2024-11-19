# frozen_string_literal: true

module Resolvers
  class ProjectPackagesProtectionRulesResolver < BaseResolver
    type Types::Packages::Protection::RuleType.connection_type, null: true

    alias_method :project, :object

    def resolve(**_args)
      project.package_protection_rules
    end
  end
end

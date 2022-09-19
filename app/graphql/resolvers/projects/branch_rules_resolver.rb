# frozen_string_literal: true

module Resolvers
  module Projects
    class BranchRulesResolver < BaseResolver
      type Types::Projects::BranchRuleType.connection_type, null: false

      alias_method :project, :object

      def resolve(**args)
        project.protected_branches
      end
    end
  end
end

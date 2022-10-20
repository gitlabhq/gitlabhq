# frozen_string_literal: true

module Resolvers
  module Projects
    class BranchRulesResolver < BaseResolver
      include LooksAhead

      type Types::Projects::BranchRuleType.connection_type, null: false

      alias_method :project, :object

      def resolve_with_lookahead(**args)
        apply_lookahead(project.protected_branches)
      end
    end
  end
end

Resolvers::Projects::BranchRulesResolver.prepend_mod_with('Resolvers::Projects::BranchRulesResolver')

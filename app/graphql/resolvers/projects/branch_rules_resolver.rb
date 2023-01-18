# frozen_string_literal: true

module Resolvers
  module Projects
    class BranchRulesResolver < BaseResolver
      include LooksAhead

      type Types::Projects::BranchRuleType.connection_type, null: false

      alias_method :project, :object

      def resolve_with_lookahead(**args)
        protected_branches.map do |protected_branch|
          ::Projects::BranchRule.new(project, protected_branch)
        end
      end

      private

      def protected_branches
        apply_lookahead(project.protected_branches.sorted_by_name)
      end
    end
  end
end

Resolvers::Projects::BranchRulesResolver.prepend_mod_with('Resolvers::Projects::BranchRulesResolver')

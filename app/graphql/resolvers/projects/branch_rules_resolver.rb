# frozen_string_literal: true

module Resolvers
  module Projects
    class BranchRulesResolver < BaseResolver
      include LooksAhead
      include ::Gitlab::Utils::StrongMemoize

      type Types::Projects::BranchRuleType.connection_type, null: false

      alias_method :project, :object

      def resolve_with_lookahead(**args)
        [*custom_branch_rules(args), *branch_rules]
      end

      private

      # BranchRules for 'All branches' i.e. no associated ProtectedBranch
      def custom_branch_rules(args)
        return [] unless squash_settings_enabled?

        [all_branches_rule]
      end

      def all_branches_rule
        ::Projects::AllBranchesRule.new(project)
      end
      strong_memoize_attr :all_branches_rule

      def branch_rules
        protected_branches.map do |protected_branch|
          ::Projects::BranchRule.new(project, protected_branch)
        end
      end

      def protected_branches
        apply_lookahead(project.all_protected_branches.sorted_by_name)
      end

      def squash_settings_enabled?
        Feature.enabled?(:branch_rule_squash_settings, project)
      end
    end
  end
end

Resolvers::Projects::BranchRulesResolver.prepend_mod_with('Resolvers::Projects::BranchRulesResolver')

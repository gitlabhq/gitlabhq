# frozen_string_literal: true

module Resolvers
  module Projects
    class BranchRulesResolver < BaseResolver
      include LooksAhead
      include ::Gitlab::Utils::StrongMemoize

      type Types::Projects::BranchRuleType.connection_type, null: false

      alias_method :project, :object

      def resolve_with_lookahead(**args)
        externally_paginated_array(branch_rules_page(args))
      end

      private

      def externally_paginated_array(page)
        has_next_page = page.has_next_page
        Gitlab::Graphql::ExternallyPaginatedArray.new(nil, page.end_cursor, *page.rules, has_next_page:)
      end

      # BranchRules for 'All branches' i.e. no associated ProtectedBranch
      def custom_branch_rules(args)
        [all_branches_rule]
      end

      def all_branches_rule
        ::Projects::AllBranchesRule.new(project)
      end
      strong_memoize_attr :all_branches_rule

      def branch_rules_page(args)
        # limit to the first 100 branch rules to match existing behaviour until frontend implements pagination.
        limit = args[:first] || 100

        ::Projects::BranchRulesFinder.new(
          project,
          custom_rules: custom_branch_rules(args),
          protected_branches: protected_branches
        ).execute(cursor: args[:after], limit: limit)
      end

      def protected_branches
        apply_lookahead(project.all_protected_branches.sorted_by_name)
      end
    end
  end
end

Resolvers::Projects::BranchRulesResolver.prepend_mod_with('Resolvers::Projects::BranchRulesResolver')

# frozen_string_literal: true

module Resolvers
  class IssueStatusCountsResolver < BaseResolver
    prepend IssueResolverArguments

    type Types::IssueStatusCountsType, null: true
    accept_release_tag

    extras [:lookahead]

    def continue_issue_resolve(parent, finder, **args)
      finder.parent_param = parent
      apply_lookahead(Gitlab::IssuablesCountForState.new(finder, parent))
    end
  end
end

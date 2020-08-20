# frozen_string_literal: true

module Resolvers
  class IssueStatusCountsResolver < BaseResolver
    prepend IssueResolverFields

    type Types::IssueStatusCountsType, null: true

    def continue_issue_resolve(parent, finder, **args)
      Gitlab::IssuablesCountForState.new(finder, parent)
    end
  end
end

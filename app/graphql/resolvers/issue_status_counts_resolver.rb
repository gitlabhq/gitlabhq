# frozen_string_literal: true

module Resolvers
  class IssueStatusCountsResolver < BaseResolver
    prepend IssueResolverFields

    type Types::IssueStatusCountsType, null: true

    def continue_issue_resolve(parent, finder, **args)
      finder.params[parent_param(parent)] = parent if parent
      apply_lookahead(Gitlab::IssuablesCountForState.new(finder, parent))
    end

    private

    def parent_param(parent)
      case parent
      when Project
        :project_id
      when Group
        :group_id
      else
        raise "Unexpected type of parent: #{parent.class}. Must be Project or Group"
      end
    end
  end
end

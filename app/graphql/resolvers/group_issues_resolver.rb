# frozen_string_literal: true

module Resolvers
  class GroupIssuesResolver < IssuesResolver
    include GroupIssuableResolver

    include_subgroups 'issues'
  end
end

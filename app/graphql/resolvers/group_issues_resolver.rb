# frozen_string_literal: true
# rubocop:disable Graphql/ResolverType (inherited from IssuesResolver)

module Resolvers
  class GroupIssuesResolver < IssuesResolver
    include GroupIssuableResolver

    include_subgroups 'issues'
  end
end

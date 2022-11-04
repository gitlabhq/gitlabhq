# frozen_string_literal: true
# rubocop:disable Graphql/ResolverType (inherited from BaseIssuesResolver)

module Resolvers
  class IssuesResolver < Issues::BaseParentResolver
    accept_release_tag
  end
end

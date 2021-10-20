# frozen_string_literal: true
# rubocop:disable Graphql/ResolverType (inherited from BaseIssuesResolver)

module Resolvers
  class IssuesResolver < BaseIssuesResolver
    accept_release_tag
  end
end

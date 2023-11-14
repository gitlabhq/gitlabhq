# frozen_string_literal: true

# rubocop:disable Graphql/ResolverType -- inherited from Issues::BaseParentResolver
module Resolvers
  class ProjectIssuesResolver < Issues::BaseParentResolver
    accept_release_tag
  end
end
# rubocop:enable Graphql/ResolverType

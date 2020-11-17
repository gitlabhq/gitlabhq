# frozen_string_literal: true
# rubocop:disable Graphql/ResolverType (inherited from MembersResolver)

module Resolvers
  class ProjectMembersResolver < MembersResolver
    authorize :read_project_member

    private

    def finder_class
      MembersFinder
    end
  end
end

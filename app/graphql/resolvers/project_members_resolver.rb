# frozen_string_literal: true

# rubocop:disable Graphql/ResolverType -- inherited from MembersResolver

module Resolvers
  class ProjectMembersResolver < MembersResolver
    authorize :read_project_member

    argument :relations, [Types::ProjectMemberRelationEnum],
      description: 'Filter members by the given member relations.',
      required: false,
      default_value: MembersFinder::DEFAULT_RELATIONS

    private

    def finder_class
      MembersFinder
    end
  end
end
# rubocop:enable Graphql/ResolverType

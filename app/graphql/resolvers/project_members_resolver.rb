# frozen_string_literal: true

# rubocop:disable Graphql/ResolverType -- inherited from MembersResolver

module Resolvers
  class ProjectMembersResolver < MembersResolver
    authorize :read_project_member

    argument :relations, [Types::ProjectMemberRelationEnum],
      description: 'Filter members by the given member relations.',
      required: false,
      default_value: MembersFinder::DEFAULT_RELATIONS

    argument :access_levels, [Types::AccessLevelEnum],
      description: 'Filter members by the given access levels.',
      required: false

    argument :ids, [GraphQL::Types::ID],
      required: false,
      description: 'List of project members IDs.',
      prepare: ->(global_ids, _ctx) {
        GitlabSchema.parse_gids(global_ids, expected_type: ::User).map(&:model_id)
      }

    argument :user_types, [Types::Users::TypeEnum],
      required: false,
      description: 'Filter by user type.',
      experiment: { milestone: '18.3' }

    private

    def finder_class
      MembersFinder
    end
  end
end
# rubocop:enable Graphql/ResolverType

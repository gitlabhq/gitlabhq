# frozen_string_literal: true

module Resolvers
  class GroupMembersResolver < MembersResolver
    type Types::GroupMemberType.connection_type, null: true

    authorize :read_group_member

    argument :relations, [Types::GroupMemberRelationEnum],
      description: 'Filter members by the given member relations.',
      required: false,
      default_value: GroupMembersFinder::DEFAULT_RELATIONS

    argument :access_levels, [Types::AccessLevelEnum],
      description: 'Filter members by the given access levels.',
      required: false

    argument :enterprise, GraphQL::Types::Boolean,
      description: 'Filter members by enterprise users.',
      required: false

    private

    def finder_class
      GroupMembersFinder
    end
  end
end

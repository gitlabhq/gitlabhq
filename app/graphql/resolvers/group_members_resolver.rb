# frozen_string_literal: true

module Resolvers
  class GroupMembersResolver < MembersResolver
    type Types::GroupMemberType.connection_type, null: true

    authorize :read_group_member

    private

    def preloads
      {
      user: [:user, :source]
      }
    end

    def finder_class
      GroupMembersFinder
    end
  end
end

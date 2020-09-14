# frozen_string_literal: true

module Resolvers
  class GroupMembersResolver < MembersResolver
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

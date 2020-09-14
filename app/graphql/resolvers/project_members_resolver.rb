# frozen_string_literal: true

module Resolvers
  class ProjectMembersResolver < MembersResolver
    type Types::MemberInterface, null: true

    authorize :read_project_member

    private

    def finder_class
      MembersFinder
    end
  end
end

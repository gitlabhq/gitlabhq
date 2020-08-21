# frozen_string_literal: true

module Resolvers
  class ProjectMembersResolver < BaseResolver
    include Gitlab::Graphql::Authorize::AuthorizeResource

    argument :search, GraphQL::STRING_TYPE,
              required: false,
              description: 'Search query'

    type Types::MemberInterface, null: true

    authorize :read_project_member

    alias_method :project, :object

    def resolve(**args)
      authorize!(project)

      MembersFinder
        .new(project, current_user, params: args)
        .execute
    end
  end
end

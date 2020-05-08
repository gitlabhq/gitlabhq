# frozen_string_literal: true

module Resolvers
  class ProjectsResolver < BaseResolver
    type Types::ProjectType, null: true

    argument :membership, GraphQL::BOOLEAN_TYPE,
             required: false,
             description: 'Limit projects that the current user is a member of'

    argument :search, GraphQL::STRING_TYPE,
             required: false,
             description: 'Search criteria'

    def resolve(**args)
      ProjectsFinder
        .new(current_user: current_user, params: project_finder_params(args))
        .execute
    end

    private

    def project_finder_params(params)
      {
        without_deleted: true,
        non_public: params[:membership],
        search: params[:search]
      }.compact
    end
  end
end

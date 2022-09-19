# frozen_string_literal: true

module Resolvers
  class ProjectsResolver < BaseResolver
    include ProjectSearchArguments

    type Types::ProjectType, null: true

    argument :ids, [GraphQL::Types::ID],
             required: false,
             description: 'Filter projects by IDs.'

    argument :sort, GraphQL::Types::String,
             required: false,
             description: "Sort order of results. Format: `<field_name>_<sort_direction>`, " \
                 "for example: `id_desc` or `name_asc`"

    def resolve(**args)
      ProjectsFinder
        .new(current_user: current_user, params: project_finder_params(args), project_ids_relation: parse_gids(args[:ids]))
        .execute
    end

    private

    def parse_gids(gids)
      gids&.map { |gid| GitlabSchema.parse_gid(gid, expected_type: ::Project).model_id }
    end
  end
end

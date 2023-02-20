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

    argument :with_issues_enabled, GraphQL::Types::Boolean,
             required: false,
             description: "Return only projects with issues enabled."

    argument :with_merge_requests_enabled, GraphQL::Types::Boolean,
             required: false,
             description: "Return only projects with merge requests enabled."

    def resolve(**args)
      ProjectsFinder
        .new(current_user: current_user, params: finder_params(args), project_ids_relation: parse_gids(args[:ids]))
        .execute
    end

    private

    def finder_params(args)
      {
        **project_finder_params(args),
        with_issues_enabled: args[:with_issues_enabled],
        with_merge_requests_enabled: args[:with_merge_requests_enabled]
      }
    end

    def parse_gids(gids)
      gids&.map { |gid| GitlabSchema.parse_gid(gid, expected_type: ::Project).model_id }
    end
  end
end

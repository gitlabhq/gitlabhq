# frozen_string_literal: true

module Resolvers
  class ProjectsResolver < BaseResolver
    include ProjectSearchArguments
    include LooksAhead

    type Types::ProjectType.connection_type, null: true

    argument :ids, [GraphQL::Types::ID],
             required: false,
             description: 'Filter projects by IDs.'

    argument :full_paths, [GraphQL::Types::String],
             required: false,
             description: 'Filter projects by full paths. You cannot provide more than 50 full paths.'

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

    def resolve_with_lookahead(**args)
      validate_args!(args)

      projects = ProjectsFinder
        .new(current_user: current_user, params: finder_params(args), project_ids_relation: parse_gids(args[:ids]))
        .execute

      apply_lookahead(projects)
    end

    private

    def validate_args!(args)
      return unless args[:full_paths].present? && args[:full_paths].length > 50

      raise Gitlab::Graphql::Errors::ArgumentError, 'You cannot provide more than 50 full_paths'
    end

    def unconditional_includes
      [:creator, :group, :invited_groups, :project_setting]
    end

    def preloads
      {
        full_path: [:route],
        topics: [:topics],
        import_status: [:import_state],
        service_desk_address: [:project_feature, :service_desk_setting],
        jira_import_status: [:jira_imports],
        container_repositories: [:container_repositories],
        container_repositories_count: [:container_repositories],
        web_url: { namespace: [:route] },
        is_catalog_resource: [:catalog_resource]
      }
    end

    def finder_params(args)
      {
        **project_finder_params(args),
        with_issues_enabled: args[:with_issues_enabled],
        with_merge_requests_enabled: args[:with_merge_requests_enabled],
        full_paths: args[:full_paths]
      }
    end

    def parse_gids(gids)
      gids&.map { |gid| GitlabSchema.parse_gid(gid, expected_type: ::Project).model_id }
    end
  end
end

Resolvers::ProjectsResolver.prepend_mod_with('Resolvers::ProjectsResolver')

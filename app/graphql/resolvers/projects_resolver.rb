# frozen_string_literal: true

module Resolvers
  class ProjectsResolver < BaseResolver
    prepend ::Projects::LookAheadPreloads
    include ProjectSearchArguments

    type Types::ProjectType.connection_type, null: true

    argument :ids, [GraphQL::Types::ID],
      required: false,
      description: 'Filter projects by IDs.'

    argument :full_paths, [GraphQL::Types::String],
      required: false,
      description: 'Filter projects by full paths. You cannot provide more than 50 full paths.'

    argument :with_issues_enabled, GraphQL::Types::Boolean,
      required: false,
      description: "Return only projects with issues enabled."

    argument :with_merge_requests_enabled, GraphQL::Types::Boolean,
      required: false,
      description: "Return only projects with merge requests enabled."

    argument :archived, ::Types::Projects::ArchivedEnum,
      required: false,
      description: 'Filter projects by archived status.'

    argument :min_access_level, ::Types::AccessLevelEnum,
      required: false,
      description: 'Return only projects where current user has at least the specified access level.'

    argument :programming_language_name, GraphQL::Types::String,
      required: false,
      description: 'Filter projects by programming language name (case insensitive). For example: "css" or "ruby".'

    argument :trending, GraphQL::Types::Boolean,
      required: false,
      description: "Return only projects that are trending."

    argument :aimed_for_deletion, GraphQL::Types::Boolean,
      required: false,
      description: 'Return only projects marked for deletion.'

    argument :not_aimed_for_deletion, GraphQL::Types::Boolean,
      required: false,
      description: "Exclude projects that are marked for deletion."

    argument :marked_for_deletion_on, ::Types::DateType,
      required: false,
      description: 'Date when the project was marked for deletion.'

    argument :active, GraphQL::Types::Boolean,
      required: false,
      description: "Filters by projects that are not archived and not marked for deletion."

    argument :visibility_level, ::Types::VisibilityLevelsEnum,
      required: false,
      description: 'Filter projects by visibility level.'

    before_connection_authorization do |projects, current_user|
      ::Preloaders::UserMaxAccessLevelInProjectsPreloader.new(projects, current_user).execute
    end

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
      [
        :creator,
        :group,
        :invited_groups,
        :project_setting,
        :project_namespace,
        {
          namespace: [:namespace_settings_with_ancestors_inherited_settings]
        }
      ]
    end

    def finder_params(args)
      {
        **project_finder_params(args),
        with_issues_enabled: args[:with_issues_enabled],
        with_merge_requests_enabled: args[:with_merge_requests_enabled],
        full_paths: args[:full_paths],
        archived: args[:archived],
        min_access_level: args[:min_access_level],
        language_name: args[:programming_language_name],
        trending: args[:trending],
        aimed_for_deletion: args[:aimed_for_deletion],
        not_aimed_for_deletion: args[:not_aimed_for_deletion],
        marked_for_deletion_on: args[:marked_for_deletion_on],
        visibility_level: args[:visibility_level],
        active: args[:active],
        current_organization: ::Current.organization
      }
    end

    def parse_gids(gids)
      gids&.map { |gid| GitlabSchema.parse_gid(gid, expected_type: ::Project).model_id }
    end
  end
end

Resolvers::ProjectsResolver.prepend_mod_with('Resolvers::ProjectsResolver')

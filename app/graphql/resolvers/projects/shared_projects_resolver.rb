# frozen_string_literal: true

module Resolvers
  module Projects
    class SharedProjectsResolver < BaseResolver
      prepend ::Projects::LookAheadPreloads

      type Types::ProjectType.connection_type, null: true

      argument :search, GraphQL::Types::String,
        required: false,
        description: 'Search query, which can be for the project name, a path, or a description.'

      argument :sort, GraphQL::Types::String,
        required: false,
        default_value: nil,
        description: "Sort order of results. Format: `<field_name>_<sort_direction>`, " \
          "for example: `id_desc` or `name_asc`. Defaults to `id_desc`, or `similarity` if search used."

      argument :min_access_level, ::Types::AccessLevelEnum,
        required: false,
        description: 'Return only projects where current user has at least the specified access level.'

      argument :programming_language_name, GraphQL::Types::String,
        required: false,
        description: 'Filter projects by programming language name (case insensitive). For example: "css" or "ruby".'

      argument :active, GraphQL::Types::Boolean,
        required: false,
        description: "Filters by projects that are not archived and not marked for deletion."

      before_connection_authorization do |projects, current_user|
        ::Preloaders::UserMaxAccessLevelInProjectsPreloader.new(projects, current_user).execute
      end

      alias_method :group, :object

      def resolve_with_lookahead(**args)
        projects = GroupProjectsFinder.new(
          group: group,
          current_user: context[:current_user],
          params: finder_params(args),
          options: { only_shared: true }
        ).execute

        apply_lookahead(projects)
      end

      private

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
          search: args[:search],
          sort: args[:sort],
          min_access_level: args[:min_access_level],
          language_name: args[:programming_language_name],
          active: args[:active],
          organization: ::Current.organization
        }
      end
    end
  end
end

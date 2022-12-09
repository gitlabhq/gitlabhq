# frozen_string_literal: true

module Resolvers
  class IssuesResolver < Issues::BaseResolver
    prepend ::Issues::LookAheadPreloads
    include ::Issues::SortArguments

    argument :state, Types::IssuableStateEnum,
              required: false,
              description: 'Current state of this issue.'

    # see app/graphql/types/issue_connection.rb
    type 'Types::IssueConnection', null: true

    before_connection_authorization do |nodes, current_user|
      projects = nodes.map(&:project)
      ::Preloaders::UserMaxAccessLevelInProjectsPreloader.new(projects, current_user).execute
    end

    def resolve_with_lookahead(**args)
      return unless Feature.enabled?(:root_level_issues_query)

      issues = apply_lookahead(
        IssuesFinder.new(current_user, prepare_finder_params(args)).execute
      )

      if non_stable_cursor_sort?(args[:sort])
        # Certain complex sorts are not supported by the stable cursor pagination yet.
        # In these cases, we use offset pagination, so we return the correct connection.
        offset_pagination(issues)
      else
        issues
      end
    end
  end
end

# frozen_string_literal: true

module Resolvers
  class IssuesResolver < BaseResolver
    prepend IssueResolverArguments

    argument :state, Types::IssuableStateEnum,
              required: false,
              description: 'Current state of this issue.'
    argument :sort, Types::IssueSortEnum,
              description: 'Sort issues by this criteria.',
              required: false,
              default_value: :created_desc

    type Types::IssueType.connection_type, null: true

    NON_STABLE_CURSOR_SORTS = %i[priority_asc priority_desc
                                 popularity_asc popularity_desc
                                 label_priority_asc label_priority_desc
                                 milestone_due_asc milestone_due_desc].freeze

    def continue_issue_resolve(parent, finder, **args)
      issues = Gitlab::Graphql::Loaders::IssuableLoader.new(parent, finder).batching_find_all { |q| apply_lookahead(q) }

      if non_stable_cursor_sort?(args[:sort])
        # Certain complex sorts are not supported by the stable cursor pagination yet.
        # In these cases, we use offset pagination, so we return the correct connection.
        offset_pagination(issues)
      else
        issues
      end
    end

    private

    def unconditional_includes
      [
        {
          project: [:project_feature]
        }
      ]
    end

    def preloads
      {
        alert_management_alert: [:alert_management_alert],
        labels: [:labels],
        assignees: [:assignees],
        timelogs: [:timelogs]
      }
    end

    def non_stable_cursor_sort?(sort)
      NON_STABLE_CURSOR_SORTS.include?(sort)
    end
  end
end

Resolvers::IssuesResolver.prepend_mod_with('Resolvers::IssuesResolver')

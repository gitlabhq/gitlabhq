# frozen_string_literal: true

module Resolvers
  class IssuesResolver < BaseResolver
    argument :iid, GraphQL::STRING_TYPE,
              required: false,
              description: 'IID of the issue. For example, "1"'

    argument :iids, [GraphQL::STRING_TYPE],
              required: false,
              description: 'List of IIDs of issues. For example, [1, 2]'
    argument :state, Types::IssuableStateEnum,
              required: false,
              description: 'Current state of this issue'
    argument :label_name, GraphQL::STRING_TYPE.to_list_type,
              required: false,
              description: 'Labels applied to this issue'
    argument :milestone_title, GraphQL::STRING_TYPE.to_list_type,
              required: false,
              description: 'Milestones applied to this issue'
    argument :assignee_username, GraphQL::STRING_TYPE,
              required: false,
              description: 'Username of a user assigned to the issues'
    argument :assignee_id, GraphQL::STRING_TYPE,
              required: false,
              description: 'ID of a user assigned to the issues, "none" and "any" values supported'
    argument :created_before, Types::TimeType,
              required: false,
              description: 'Issues created before this date'
    argument :created_after, Types::TimeType,
              required: false,
              description: 'Issues created after this date'
    argument :updated_before, Types::TimeType,
              required: false,
              description: 'Issues updated before this date'
    argument :updated_after, Types::TimeType,
              required: false,
              description: 'Issues updated after this date'
    argument :closed_before, Types::TimeType,
              required: false,
              description: 'Issues closed before this date'
    argument :closed_after, Types::TimeType,
              required: false,
              description: 'Issues closed after this date'
    argument :search, GraphQL::STRING_TYPE,
              required: false,
              description: 'Search query for finding issues by title or description'
    argument :sort, Types::IssueSortEnum,
              description: 'Sort issues by this criteria',
              required: false,
              default_value: 'created_desc'

    type Types::IssueType, null: true

    NON_STABLE_CURSOR_SORTS = %i[priority_asc priority_desc label_priority_asc label_priority_desc].freeze

    def resolve(**args)
      # The project could have been loaded in batch by `BatchLoader`.
      # At this point we need the `id` of the project to query for issues, so
      # make sure it's loaded and not `nil` before continuing.
      parent = object.respond_to?(:sync) ? object.sync : object
      return Issue.none if parent.nil?

      if parent.is_a?(Group)
        args[:group_id] = parent.id
      else
        args[:project_id] = parent.id
      end

      # Will need to be be made group & namespace aware with
      # https://gitlab.com/gitlab-org/gitlab-foss/issues/54520
      args[:iids] ||= [args[:iid]].compact
      args[:attempt_project_search_optimizations] = args[:search].present?

      issues = IssuesFinder.new(context[:current_user], args).execute

      if non_stable_cursor_sort?(args[:sort])
        # Certain complex sorts are not supported by the stable cursor pagination yet.
        # In these cases, we use offset pagination, so we return the correct connection.
        Gitlab::Graphql::Pagination::OffsetActiveRecordRelationConnection.new(issues)
      else
        issues
      end
    end

    def self.resolver_complexity(args, child_complexity:)
      complexity = super
      complexity += 2 if args[:labelName]

      complexity
    end

    def non_stable_cursor_sort?(sort)
      NON_STABLE_CURSOR_SORTS.include?(sort)
    end
  end
end

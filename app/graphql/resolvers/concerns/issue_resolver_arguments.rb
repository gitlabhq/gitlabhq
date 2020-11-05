# frozen_string_literal: true

module IssueResolverArguments
  extend ActiveSupport::Concern

  prepended do
    include LooksAhead

    argument :iid, GraphQL::STRING_TYPE,
              required: false,
              description: 'IID of the issue. For example, "1"'
    argument :iids, [GraphQL::STRING_TYPE],
              required: false,
              description: 'List of IIDs of issues. For example, [1, 2]'
    argument :label_name, GraphQL::STRING_TYPE.to_list_type,
              required: false,
              description: 'Labels applied to this issue'
    argument :milestone_title, GraphQL::STRING_TYPE.to_list_type,
              required: false,
              description: 'Milestone applied to this issue'
    argument :author_username, GraphQL::STRING_TYPE,
              required: false,
              description: 'Username of the author of the issue'
    argument :assignee_username, GraphQL::STRING_TYPE,
              required: false,
              description: 'Username of a user assigned to the issue'
    argument :assignee_usernames, [GraphQL::STRING_TYPE],
              required: false,
              description: 'Usernames of users assigned to the issue'
    argument :assignee_id, GraphQL::STRING_TYPE,
              required: false,
              description: 'ID of a user assigned to the issues, "none" and "any" values are supported'
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
              description: 'Search query for issue title or description'
    argument :types, [Types::IssueTypeEnum],
              as: :issue_types,
              description: 'Filter issues by the given issue types',
              required: false
  end

  def resolve_with_lookahead(**args)
    # The project could have been loaded in batch by `BatchLoader`.
    # At this point we need the `id` of the project to query for issues, so
    # make sure it's loaded and not `nil` before continuing.
    parent = object.respond_to?(:sync) ? object.sync : object
    return Issue.none if parent.nil?

    # Will need to be made group & namespace aware with
    # https://gitlab.com/gitlab-org/gitlab-foss/issues/54520
    args[:iids] ||= [args.delete(:iid)].compact if args[:iid]
    args[:attempt_project_search_optimizations] = true if args[:search].present?

    finder = IssuesFinder.new(current_user, args)

    continue_issue_resolve(parent, finder, **args)
  end

  class_methods do
    def resolver_complexity(args, child_complexity:)
      complexity = super
      complexity += 2 if args[:labelName]

      complexity
    end
  end
end

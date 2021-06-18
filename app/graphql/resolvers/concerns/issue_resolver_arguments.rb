# frozen_string_literal: true

module IssueResolverArguments
  extend ActiveSupport::Concern

  prepended do
    include LooksAhead

    argument :iid, GraphQL::STRING_TYPE,
             required: false,
             description: 'IID of the issue. For example, "1".'
    argument :iids, [GraphQL::STRING_TYPE],
             required: false,
             description: 'List of IIDs of issues. For example, `["1", "2"]`.'
    argument :label_name, [GraphQL::STRING_TYPE, null: true],
             required: false,
             description: 'Labels applied to this issue.'
    argument :milestone_title, [GraphQL::STRING_TYPE, null: true],
             required: false,
             description: 'Milestone applied to this issue.'
    argument :author_username, GraphQL::STRING_TYPE,
             required: false,
             description: 'Username of the author of the issue.'
    argument :assignee_username, GraphQL::STRING_TYPE,
             required: false,
             description: 'Username of a user assigned to the issue.',
             deprecated: { reason: 'Use `assigneeUsernames`', milestone: '13.11' }
    argument :assignee_usernames, [GraphQL::STRING_TYPE],
             required: false,
             description: 'Usernames of users assigned to the issue.'
    argument :assignee_id, GraphQL::STRING_TYPE,
             required: false,
             description: 'ID of a user assigned to the issues, "none" and "any" values are supported.'
    argument :created_before, Types::TimeType,
             required: false,
             description: 'Issues created before this date.'
    argument :created_after, Types::TimeType,
             required: false,
             description: 'Issues created after this date.'
    argument :updated_before, Types::TimeType,
             required: false,
             description: 'Issues updated before this date.'
    argument :updated_after, Types::TimeType,
             required: false,
             description: 'Issues updated after this date.'
    argument :closed_before, Types::TimeType,
             required: false,
             description: 'Issues closed before this date.'
    argument :closed_after, Types::TimeType,
             required: false,
             description: 'Issues closed after this date.'
    argument :search, GraphQL::STRING_TYPE,
             required: false,
             description: 'Search query for issue title or description.'
    argument :types, [Types::IssueTypeEnum],
             as: :issue_types,
             description: 'Filter issues by the given issue types.',
             required: false
    argument :not, Types::Issues::NegatedIssueFilterInputType,
             description: 'Negated arguments.',
             prepare: ->(negated_args, ctx) { negated_args.to_h },
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

    prepare_assignee_username_params(args)

    finder = IssuesFinder.new(current_user, args)

    continue_issue_resolve(parent, finder, **args)
  end

  def ready?(**args)
    if args.slice(*mutually_exclusive_assignee_username_args).compact.size > 1
      arg_str = mutually_exclusive_assignee_username_args.map { |x| x.to_s.camelize(:lower) }.join(', ')
      raise Gitlab::Graphql::Errors::ArgumentError, "only one of [#{arg_str}] arguments is allowed at the same time."
    end

    super
  end

  class_methods do
    def resolver_complexity(args, child_complexity:)
      complexity = super
      complexity += 2 if args[:labelName]

      complexity
    end
  end

  private

  def prepare_assignee_username_params(args)
    args[:assignee_username] = args.delete(:assignee_usernames) if args[:assignee_usernames].present?
    args[:not][:assignee_username] = args[:not].delete(:assignee_usernames) if args.dig(:not, :assignee_usernames).present?
  end

  def mutually_exclusive_assignee_username_args
    [:assignee_usernames, :assignee_username]
  end
end

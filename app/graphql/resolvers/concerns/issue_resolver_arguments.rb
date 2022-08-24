# frozen_string_literal: true

module IssueResolverArguments
  extend ActiveSupport::Concern

  prepended do
    include SearchArguments
    include LooksAhead

    argument :iid, GraphQL::Types::String,
             required: false,
             description: 'IID of the issue. For example, "1".'
    argument :iids, [GraphQL::Types::String],
             required: false,
             description: 'List of IIDs of issues. For example, `["1", "2"]`.'
    argument :label_name, [GraphQL::Types::String, null: true],
             required: false,
             description: 'Labels applied to this issue.'
    argument :milestone_title, [GraphQL::Types::String, null: true],
             required: false,
             description: 'Milestone applied to this issue.'
    argument :author_username, GraphQL::Types::String,
             required: false,
             description: 'Username of the author of the issue.'
    argument :assignee_username, GraphQL::Types::String,
             required: false,
             description: 'Username of a user assigned to the issue.',
             deprecated: { reason: 'Use `assigneeUsernames`', milestone: '13.11' }
    argument :assignee_usernames, [GraphQL::Types::String],
             required: false,
             description: 'Usernames of users assigned to the issue.'
    argument :assignee_id, GraphQL::Types::String,
             required: false,
             description: 'ID of a user assigned to the issues. Wildcard values "NONE" and "ANY" are supported.'
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
    argument :types, [Types::IssueTypeEnum],
             as: :issue_types,
             description: 'Filter issues by the given issue types.',
             required: false
    argument :milestone_wildcard_id, ::Types::MilestoneWildcardIdEnum,
             required: false,
             description: 'Filter issues by milestone ID wildcard.'
    argument :my_reaction_emoji, GraphQL::Types::String,
             required: false,
             description: 'Filter by reaction emoji applied by the current user. Wildcard values "NONE" and "ANY" are supported.'
    argument :confidential,
             GraphQL::Types::Boolean,
             required: false,
             description: 'Filter for confidential issues. If "false", excludes confidential issues. If "true", returns only confidential issues.'
    argument :not, Types::Issues::NegatedIssueFilterInputType,
             description: 'Negated arguments.',
             required: false
    argument :crm_contact_id, GraphQL::Types::String,
             required: false,
             description: 'ID of a contact assigned to the issues.'
    argument :crm_organization_id, GraphQL::Types::String,
             required: false,
             description: 'ID of an organization assigned to the issues.'
  end

  def resolve_with_lookahead(**args)
    return Issue.none if resource_parent.nil?

    finder = IssuesFinder.new(current_user, prepare_finder_params(args))

    continue_issue_resolve(resource_parent, finder, **args)
  end

  def ready?(**args)
    args[:not] = args[:not].to_h if args[:not].present?

    params_not_mutually_exclusive(args, mutually_exclusive_assignee_username_args)
    params_not_mutually_exclusive(args, mutually_exclusive_milestone_args)
    params_not_mutually_exclusive(args.fetch(:not, {}), mutually_exclusive_milestone_args)
    params_not_mutually_exclusive(args, mutually_exclusive_release_tag_args)

    super
  end

  class_methods do
    def resolver_complexity(args, child_complexity:)
      complexity = super
      complexity += 2 if args[:labelName]

      complexity
    end

    def accept_release_tag
      argument :release_tag, [GraphQL::Types::String],
               required: false,
               description: "Release tag associated with the issue's milestone."
      argument :release_tag_wildcard_id, Types::ReleaseTagWildcardIdEnum,
               required: false,
               description: 'Filter issues by release tag ID wildcard.'
    end
  end

  private

  def prepare_finder_params(args)
    params = super(args)
    params[:iids] ||= [params.delete(:iid)].compact if params[:iid]
    params[:attempt_project_search_optimizations] = true if params[:search].present?

    prepare_assignee_username_params(params)
    prepare_release_tag_params(params)

    params
  end

  def prepare_release_tag_params(args)
    release_tag_wildcard = args.delete(:release_tag_wildcard_id)
    return if release_tag_wildcard.blank?

    args[:release_tag] ||= release_tag_wildcard
  end

  def prepare_assignee_username_params(args)
    args[:assignee_username] = args.delete(:assignee_usernames) if args[:assignee_usernames].present?
    args[:not][:assignee_username] = args[:not].delete(:assignee_usernames) if args.dig(:not, :assignee_usernames).present?
  end

  def mutually_exclusive_release_tag_args
    [:release_tag, :release_tag_wildcard_id]
  end

  def mutually_exclusive_milestone_args
    [:milestone_title, :milestone_wildcard_id]
  end

  def mutually_exclusive_assignee_username_args
    [:assignee_usernames, :assignee_username]
  end

  def params_not_mutually_exclusive(args, mutually_exclusive_args)
    if args.slice(*mutually_exclusive_args).compact.size > 1
      arg_str = mutually_exclusive_args.map { |x| x.to_s.camelize(:lower) }.join(', ')
      raise ::Gitlab::Graphql::Errors::ArgumentError, "only one of [#{arg_str}] arguments is allowed at the same time."
    end
  end

  def resource_parent
    # The project could have been loaded in batch by `BatchLoader`.
    # At this point we need the `id` of the project to query for issues, so
    # make sure it's loaded and not `nil` before continuing.
    strong_memoize(:resource_parent) do
      object.respond_to?(:sync) ? object.sync : object
    end
  end
end

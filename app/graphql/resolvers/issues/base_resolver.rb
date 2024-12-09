# frozen_string_literal: true

module Resolvers
  module Issues
    # rubocop:disable Graphql/ResolverType
    class BaseResolver < Resolvers::BaseResolver
      include SearchArguments

      argument :assignee_id, GraphQL::Types::String,
        required: false,
        description: 'ID of a user assigned to the issues. Wildcard values "NONE" and "ANY" are supported.'
      argument :assignee_username, GraphQL::Types::String,
        required: false,
        description: 'Username of a user assigned to the issue.',
        deprecated: { reason: 'Use `assigneeUsernames`', milestone: '13.11' }
      argument :assignee_usernames, [GraphQL::Types::String],
        required: false,
        description: 'Usernames of users assigned to the issue.'
      argument :assignee_wildcard_id, ::Types::AssigneeWildcardIdEnum,
        required: false,
        description: 'Filter by assignee wildcard. Incompatible with assigneeUsername and assigneeUsernames.'
      argument :author_username, GraphQL::Types::String,
        required: false,
        description: 'Username of the author of the issue.'
      argument :closed_after, Types::TimeType,
        required: false,
        description: 'Issues closed after the date.'
      argument :closed_before, Types::TimeType,
        required: false,
        description: 'Issues closed before the date.'
      argument :confidential,
        GraphQL::Types::Boolean,
        required: false,
        description: 'Filter for confidential issues. If "false", excludes confidential issues. ' \
          'If "true", returns only confidential issues.'
      argument :created_after, Types::TimeType,
        required: false,
        description: 'Issues created after the date.'
      argument :created_before, Types::TimeType,
        required: false,
        description: 'Issues created before the date.'
      argument :crm_contact_id, GraphQL::Types::String,
        required: false,
        description: 'ID of a contact assigned to the issues.'
      argument :crm_organization_id, GraphQL::Types::String,
        required: false,
        description: 'ID of an organization assigned to the issues.'
      argument :due_after, Types::TimeType,
        required: false,
        description: 'Return issues due on or after the given time.'
      argument :due_before, Types::TimeType,
        required: false,
        description: 'Return issues due on or before the given time.'
      argument :iid, GraphQL::Types::String,
        required: false,
        description: 'IID of the issue. For example, "1".'
      argument :iids, [GraphQL::Types::String],
        required: false,
        description: 'List of IIDs of issues. For example, `["1", "2"]`.'
      argument :label_name, [GraphQL::Types::String, { null: true }],
        required: false,
        description: 'Labels applied to the issue.'
      argument :milestone_title, [GraphQL::Types::String, { null: true }],
        required: false,
        description: 'Milestone applied to the issue.'
      argument :milestone_wildcard_id, ::Types::MilestoneWildcardIdEnum,
        required: false,
        description: 'Filter issues by milestone ID wildcard.'
      argument :my_reaction_emoji, GraphQL::Types::String,
        required: false,
        description: 'Filter by reaction emoji applied by the current user. ' \
          'Wildcard values "NONE" and "ANY" are supported.'
      argument :not, Types::Issues::NegatedIssueFilterInputType,
        description: 'Negated arguments.',
        required: false
      argument :or, Types::Issues::UnionedIssueFilterInputType,
        description: 'List of arguments with inclusive OR.',
        required: false
      argument :subscribed, Types::Issuables::SubscriptionStatusEnum,
        description: 'Issues the current user is subscribed to.',
        required: false
      argument :types, [Types::IssueTypeEnum],
        as: :issue_types,
        description: 'Filter issues by the given issue types.',
        required: false
      argument :updated_after, Types::TimeType,
        required: false,
        description: 'Issues updated after the date.'
      argument :updated_before, Types::TimeType,
        required: false,
        description: 'Issues updated before the date.'

      validates mutually_exclusive: [:assignee_usernames, :assignee_username, :assignee_wildcard_id]
      validates mutually_exclusive: [:milestone_title, :milestone_wildcard_id]
      validates mutually_exclusive: [:release_tag, :release_tag_wildcard_id]

      class << self
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

      def ready?(**args)
        args[:not] = args[:not].to_h if args[:not]
        args[:or] = args[:or].to_h if args[:or]

        super
      end

      private

      def prepare_finder_params(args)
        params = super(args)
        params[:not] = params[:not].to_h if params[:not]
        params[:or] = params[:or].to_h if params[:or]
        params[:iids] ||= [params.delete(:iid)].compact if params[:iid]

        rewrite_param_name(params[:or], :author_usernames, :author_username)
        rewrite_param_name(params[:or], :label_names, :label_name)
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
        rewrite_param_name(args, :assignee_usernames, :assignee_username)
        rewrite_param_name(args[:or], :assignee_usernames, :assignee_username)
        rewrite_param_name(args[:not], :assignee_usernames, :assignee_username)
        rewrite_param_name(args, :assignee_wildcard_id, :assignee_id)
      end

      def rewrite_param_name(params, old_name, new_name)
        params[new_name] = params.delete(old_name) if params && params[old_name].present?
      end
    end
    # rubocop:enable Graphql/ResolverType
  end
end

Resolvers::Issues::BaseResolver.prepend_mod

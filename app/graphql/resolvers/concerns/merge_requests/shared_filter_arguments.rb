# frozen_string_literal: true

module MergeRequests
  module SharedFilterArguments
    extend ActiveSupport::Concern
    extend Gitlab::Utils::Override

    class_methods do
      def accept_assignee
        argument :assignee_username, GraphQL::Types::String,
          required: false,
          description: 'Username of the assignee.'
        argument :assignee_usernames, [GraphQL::Types::String],
          required: false,
          description: 'Usernames of users assigned to the merge request.'
        argument :assignee_wildcard_id, ::Types::AssigneeWildcardIdEnum,
          required: false,
          description: 'Filter by assignee presence. Incompatible with assigneeUsernames and assigneeUsername.'
      end

      def accept_author
        argument :author_username, GraphQL::Types::String,
          required: false,
          description: 'Username of the author.'
      end

      def accept_reviewer
        argument :reviewer_username, GraphQL::Types::String,
          required: false,
          description: 'Username of the reviewer.'
        argument :reviewer_wildcard_id, ::Types::ReviewerWildcardIdEnum,
          required: false,
          description: 'Filter by reviewer presence. Incompatible with reviewerUsername.'
      end
    end

    included do
      argument :approved_by, [GraphQL::Types::String],
        required: false,
        as: :approved_by_usernames,
        description: 'Usernames of the approvers.'

      argument :release_tag, GraphQL::Types::String,
        required: false,
        description: 'Filter by release tag.'

      argument :iids, [GraphQL::Types::String],
        required: false,
        description: 'Array of IIDs of merge requests, for example `[1, 2]`.'
      argument :merged_by, GraphQL::Types::String,
        required: false,
        as: :merge_user_username,
        description: 'Username of the merger.'
      argument :my_reaction_emoji, GraphQL::Types::String,
        required: false,
        description: 'Filter by your reaction emoji.'
      argument :or, Types::MergeRequests::UnionedMergeRequestFilterInputType,
        description: 'List of arguments with inclusive OR.',
        required: false

      argument :source_branches, [GraphQL::Types::String],
        required: false,
        as: :source_branch,
        description: <<~DESC
                 Array of source branch names.
                 All resolved merge requests will have one of these branches as their source.
        DESC

      argument :target_branches, [GraphQL::Types::String],
        required: false,
        as: :target_branch,
        description: <<~DESC
                 Array of target branch names.
                 All resolved merge requests will have one of these branches as their target.
        DESC

      argument :state, ::Types::MergeRequestStateEnum,
        required: false,
        description: 'Merge request state. If provided, all resolved merge requests will have the state.'

      argument :draft, GraphQL::Types::Boolean,
        required: false,
        description: 'Limit result to draft merge requests.'

      argument :blob_path, GraphQL::Types::String,
        required: false,
        experiment: { milestone: '17.7' },
        description: <<~DESC
                 Path of the blob changed in merge request.
                 Requires state, targetBranches, and createdAfter arguments.
        DESC

      argument :closed_after, Types::TimeType,
        required: false,
        description: 'Merge requests closed after the date.'
      argument :closed_before, Types::TimeType,
        required: false,
        description: 'Merge requests closed before the date.'
      argument :created_after, Types::TimeType,
        required: false,
        description: 'Merge requests created after the timestamp.'
      argument :created_before, Types::TimeType,
        required: false,
        description: 'Merge requests created before the timestamp.'
      argument :deployed_after, Types::TimeType,
        required: false,
        description: 'Merge requests deployed after the timestamp.'
      argument :deployed_before, Types::TimeType,
        required: false,
        description: 'Merge requests deployed before the timestamp.'
      argument :deployment_id, GraphQL::Types::String,
        required: false,
        description: 'ID of the deployment.'
      argument :environment_name, GraphQL::Types::String,
        as: :environment,
        required: false,
        description: 'Environment merge requests have been deployed to.'
      argument :updated_after, Types::TimeType,
        required: false,
        description: 'Merge requests updated after the timestamp.'
      argument :updated_before, Types::TimeType,
        required: false,
        description: 'Merge requests updated before the timestamp.'

      argument :ignored_reviewer_username, GraphQL::Types::String,
        required: false,
        description: 'Username of the reviewer to ignore when searching by reviewer state.',
        experiment: { milestone: '18.0' }
      argument :label_name, [GraphQL::Types::String, { null: true }],
        required: false,
        description: 'Labels applied to the merge request.'
      argument :labels, [GraphQL::Types::String],
        required: false,
        as: :label_name,
        description: 'Array of label names. All resolved merge requests will have all of these labels.',
        deprecated: { reason: 'Use `labelName`', milestone: '17.1' }
      argument :merged_after, Types::TimeType,
        required: false,
        description: 'Merge requests merged after the date.'
      argument :merged_before, Types::TimeType,
        required: false,
        description: 'Merge requests merged before the date.'
      argument :milestone_title, GraphQL::Types::String,
        required: false,
        description: 'Title of the milestone. Incompatible with milestoneWildcardId.'
      argument :milestone_wildcard_id, ::Types::MilestoneWildcardIdEnum,
        required: false,
        description: 'Filter issues by milestone ID wildcard. Incompatible with milestoneTitle.'
      argument :review_state, ::Types::MergeRequestReviewStateEnum,
        required: false,
        description: 'Reviewer state of the merge request.'
      argument :review_states, [::Types::MergeRequestReviewStateEnum],
        required: false,
        description: 'Reviewer states of the merge request.'
      argument :subscribed, Types::Issuables::SubscriptionStatusEnum,
        description: 'Merge requests the current user is subscribed to.',
        required: false

      argument :not, ::Types::MergeRequests::NegatedMergeRequestFilterInputType,
        required: false,
        description: <<~MD
                   List of negated arguments.
                   Warning: this argument is experimental and a subject to change in future.
        MD

      validates mutually_exclusive: [:assignee_usernames, :assignee_username, :assignee_wildcard_id]
      validates mutually_exclusive: [:reviewer_username, :reviewer_wildcard_id]
      validates mutually_exclusive: [:milestone_title, :milestone_wildcard_id]
    end

    private

    override :prepare_finder_params
    def prepare_finder_params(args)
      validate_blob_path!(args)
      validate_closed_range!(args)

      params = super
      params[:not] = params[:not].to_h if params[:not]
      params[:or] = params[:or].to_h if params[:or]

      rewrite_param_name(params, :reviewer_wildcard_id, :reviewer_id)
      rewrite_param_name(params, :assignee_wildcard_id, :assignee_id)
      rewrite_param_name(params, :assignee_usernames, :assignee_username)
      rewrite_param_name(params[:or], :assignee_usernames, :assignee_username)

      params
    end

    def rewrite_param_name(params, old_name, new_name)
      params[new_name] = params.delete(old_name) if params && params[old_name].present?
    end

    def validate_blob_path!(args)
      return if args[:blob_path].blank?

      required_fields = {
        target_branch: 'targetBranches',
        state: 'state',
        created_after: 'createdAfter'
      }

      required_fields.each do |key, field_name|
        if args[key].blank?
          raise Gitlab::Graphql::Errors::ArgumentError, "#{field_name} field must be specified to filter by blobPath"
        end
      end

      # It's limited for performance reasons
      created_after = args[:created_after].to_datetime
      return if created_after.after?(30.days.ago)

      raise Gitlab::Graphql::Errors::ArgumentError,
        'createdAfter must be within the last 30 days to filter by blobPath'
    end

    def validate_closed_range!(args)
      closed_after = args[:closed_after]
      closed_before = args[:closed_before]

      return if closed_after.nil? && closed_before.nil?

      if closed_after.nil? || closed_before.nil?
        raise Gitlab::Graphql::Errors::ArgumentError,
          'You must provide both closedAfter and closedBefore.'
      end

      if closed_before < closed_after
        raise Gitlab::Graphql::Errors::ArgumentError,
          'closedBefore must be on or after closedAfter.'
      end

      return unless (closed_before - closed_after) > 2.years

      raise Gitlab::Graphql::Errors::ArgumentError,
        'Time between closedAfter and closedBefore must be 2 years or less.'
    end
  end
end

MergeRequests::SharedFilterArguments.include_mod

# frozen_string_literal: true

module Mutations
  module MergeRequests
    class Accept < Base
      graphql_name 'MergeRequestAccept'
      authorize :accept_merge_request
      description <<~DESC
        Accepts a merge request.
        When accepted, the source branch will be scheduled to merge into the target branch, either
        immediately if possible, or using one of the automatic merge strategies.

        [In GitLab 16.5](https://gitlab.com/gitlab-org/gitlab/-/issues/421510), the merging happens asynchronously.
        This results in `mergeRequest` and `state` not updating after a mutation request,
        because the merging may not have happened yet.
      DESC

      NOT_MERGEABLE = 'This branch cannot be merged'
      HOOKS_VALIDATION_ERROR = 'Pre-merge hooks failed'
      SHA_MISMATCH = 'The merge-head is not at the anticipated SHA'
      MERGE_FAILED = 'The merge failed'
      ALREADY_SCHEDULED = 'The merge request is already scheduled to be merged'

      argument :strategy,
        ::Types::MergeStrategyEnum,
        required: false,
        as: :auto_merge_strategy,
        description: 'How to merge the merge request.'

      argument :commit_message, ::GraphQL::Types::String,
        required: false,
        description: 'Custom merge commit message.'
      argument :sha, ::GraphQL::Types::String,
        required: true,
        description: 'HEAD SHA at the time when the merge was requested.'
      argument :squash_commit_message, ::GraphQL::Types::String,
        required: false,
        description: 'Custom squash commit message (if squash is true).'

      argument :should_remove_source_branch, ::GraphQL::Types::Boolean,
        required: false,
        description: 'Should the source branch be removed.'
      argument :squash, ::GraphQL::Types::Boolean,
        required: false,
        default_value: false,
        description: 'Squash commits on the source branch before merge.'

      def resolve(project_path:, iid:, **args)
        Gitlab::QueryLimiting.disable!('https://gitlab.com/gitlab-org/gitlab/-/issues/4796')

        merge_request = authorized_find!(project_path: project_path, iid: iid)
        project = merge_request.target_project
        merge_params = args.compact.with_indifferent_access
        merge_service = ::MergeRequests::MergeService.new(
          project: project,
          current_user: current_user,
          params: merge_params
        )

        if error = validate(merge_request, merge_service, merge_params)
          return { merge_request: merge_request, errors: [error] }
        end

        merge_request.update(merge_error: nil, squash: merge_params[:squash])

        result = if merge_params.key?(:auto_merge_strategy)
                   service = AutoMergeService.new(project, current_user, merge_params)
                   service.execute(merge_request, merge_params[:auto_merge_strategy])
                 else
                   merge_request.merge_async(current_user.id, merge_params)
                 end

        {
          merge_request: merge_request,
          errors: result == :failed ? [MERGE_FAILED] : []
        }
      rescue ::MergeRequests::MergeBaseService::MergeError => e
        {
          merge_request: merge_request,
          errors: [e.message]
        }
      end

      def validate(merge_request, merge_service, merge_params)
        skipped_checks = merge_request.skipped_mergeable_checks(
          auto_merge_requested: merge_params.key?(:auto_merge_strategy),
          auto_merge_strategy: merge_params[:auto_merge_strategy]
        )

        if merge_request.auto_merge_enabled?
          ALREADY_SCHEDULED
        elsif !merge_request.mergeable?(**skipped_checks)
          NOT_MERGEABLE
        elsif !merge_service.hooks_validation_pass?(merge_request)
          HOOKS_VALIDATION_ERROR
        elsif merge_params[:sha] != merge_request.diff_head_sha
          SHA_MISMATCH
        end
      end
    end
  end
end

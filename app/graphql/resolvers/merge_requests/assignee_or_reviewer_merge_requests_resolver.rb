# frozen_string_literal: true

module Resolvers
  module MergeRequests
    class AssigneeOrReviewerMergeRequestsResolver < UserMergeRequestsResolverBase
      type ::Types::MergeRequestType.connection_type, null: true

      argument :assigned_review_states, [::Types::MergeRequestReviewStateEnum],
        required: false,
        description: 'Reviewer states for merge requests the current user is assigned to.'

      argument :reviewer_review_states, [::Types::MergeRequestReviewStateEnum],
        required: false,
        description: 'Reviewer states for the merge requests the current user is a reviewer of.'

      def resolve(**args)
        return unless current_user.merge_request_dashboard_enabled?

        super(**args)
      end

      def user_role
        :assigned_user
      end
    end
  end
end

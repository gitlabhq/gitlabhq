# frozen_string_literal: true

module Mutations
  module MergeRequests
    class ReviewerRereview < Base
      graphql_name 'MergeRequestReviewerRereview'

      argument :user_id, ::Types::GlobalIDType[::User],
        loads: Types::UserType,
        required: true,
        description: <<~DESC
                            User ID for the user that has been requested for a new review.
        DESC

      def resolve(project_path:, iid:, user:)
        merge_request = authorized_find!(project_path: project_path, iid: iid)

        result = ::MergeRequests::RequestReviewService.new(
          project: merge_request.project,
          current_user: current_user
        ).execute(merge_request, user)

        {
          merge_request: merge_request,
          errors: Array(result[:message])
        }
      end
    end
  end
end

# frozen_string_literal: true

module Mutations
  module MergeRequests
    class ReviewerRereview < Base
      graphql_name 'MergeRequestReviewerRereview'

      authorize_granular_token permissions: :update_merge_request,
        boundary_argument: :project_path, boundary_type: :project

      argument :user_id, ::Types::GlobalIDType[::User],
        required: true,
        description: <<~DESC
                            User ID for the user that has been requested for a new review.
        DESC

      def resolve(project_path:, iid:, user_id:)
        merge_request = authorized_find!(project_path: project_path, iid: iid)
        user = load_user(user_id)

        result = ::MergeRequests::RequestReviewService.new(
          project: merge_request.project,
          current_user: current_user
        ).execute(merge_request, user)

        {
          merge_request: merge_request,
          errors: Array(result[:message])
        }
      end

      private

      def load_user(user_id)
        user = Gitlab::Graphql::Lazy.force(GitlabSchema.find_by_gid(user_id))
        # A missing record is a not-found error, so raise GraphQL::ExecutionError to match
        # the old `loads:` behaviour. Authorization failures use raise_resource_not_available_error!
        # instead, so we don't leak that the record exists.
        raise GraphQL::ExecutionError, "No object found for `userId: #{user_id.to_s.inspect}`" unless user

        raise_resource_not_available_error! unless Ability.allowed?(current_user, :read_user, user)

        user
      end
    end
  end
end

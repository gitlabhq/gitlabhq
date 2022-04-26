# frozen_string_literal: true

module Mutations
  module MergeRequests
    class RemoveAttentionRequest < Base
      graphql_name 'MergeRequestRemoveAttentionRequest'

      argument :user_id, ::Types::GlobalIDType[::User],
               loads: Types::UserType,
               required: true,
               description: <<~DESC
                            User ID of the user for attention request removal.
               DESC

      def resolve(project_path:, iid:, user:)
        merge_request = authorized_find!(project_path: project_path, iid: iid)

        result = ::MergeRequests::RemoveAttentionRequestedService.new(
          project: merge_request.project,
          current_user: current_user,
          merge_request: merge_request,
          user: user
        ).execute

        {
          merge_request: merge_request,
          errors: Array(result[:message])
        }
      end
    end
  end
end

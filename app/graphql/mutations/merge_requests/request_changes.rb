# frozen_string_literal: true

module Mutations
  module MergeRequests
    class RequestChanges < Base
      graphql_name 'MergeRequestRequestChanges'

      def resolve(project_path:, iid:)
        merge_request = authorized_find!(project_path: project_path, iid: iid)

        result = ::MergeRequests::UpdateReviewerStateService.new(
          project: merge_request.project,
          current_user: current_user
        ).execute(merge_request, 'requested_changes')

        {
          merge_request: merge_request,
          errors: result[:status] == :success ? [] : Array(result[:message])
        }
      end
    end
  end
end

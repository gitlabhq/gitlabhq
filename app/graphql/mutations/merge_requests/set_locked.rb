# frozen_string_literal: true

module Mutations
  module MergeRequests
    class SetLocked < Base
      graphql_name 'MergeRequestSetLocked'

      argument :locked,
        GraphQL::Types::Boolean,
        required: true,
        description: <<~DESC
                 Whether or not to lock the merge request.
        DESC

      def resolve(project_path:, iid:, locked:)
        merge_request = authorized_find!(project_path: project_path, iid: iid)
        project = merge_request.project

        ::MergeRequests::UpdateService.new(
          project: project,
          current_user: current_user,
          params: { discussion_locked: locked }
        ).execute(merge_request)

        {
          merge_request: merge_request,
          errors: errors_on_object(merge_request)
        }
      end
    end
  end
end

# frozen_string_literal: true

module Mutations
  module MergeRequests
    class SetLocked < Base
      graphql_name 'MergeRequestSetLocked'

      argument :locked,
               GraphQL::BOOLEAN_TYPE,
               required: true,
               description: <<~DESC
                            Whether or not to lock the merge request.
               DESC

      def resolve(project_path:, iid:, locked:)
        merge_request = authorized_find!(project_path: project_path, iid: iid)
        project = merge_request.project

        ::MergeRequests::UpdateService.new(project, current_user, discussion_locked: locked)
          .execute(merge_request)

        {
          merge_request: merge_request,
          errors: merge_request.errors.full_messages
        }
      end
    end
  end
end

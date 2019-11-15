# frozen_string_literal: true

module Mutations
  module MergeRequests
    class SetAssignees < Base
      graphql_name 'MergeRequestSetAssignees'

      argument :assignee_usernames,
               [GraphQL::STRING_TYPE],
               required: true,
               description: <<~DESC
                            The usernames to assign to the merge request. Replaces existing assignees by default.
               DESC

      argument :operation_mode,
               Types::MutationOperationModeEnum,
               required: false,
               description: <<~DESC
                            The operation to perform. Defaults to REPLACE.
               DESC

      def resolve(project_path:, iid:, assignee_usernames:, operation_mode: Types::MutationOperationModeEnum.enum[:replace])
        Gitlab::QueryLimiting.whitelist('https://gitlab.com/gitlab-org/gitlab/issues/36098')

        merge_request = authorized_find!(project_path: project_path, iid: iid)
        project = merge_request.project

        assignee_ids = []
        assignee_ids += merge_request.assignees.map(&:id) if Types::MutationOperationModeEnum.enum.values_at(:remove, :append).include?(operation_mode)
        user_ids = UsersFinder.new(current_user, username: assignee_usernames).execute.map(&:id)

        if operation_mode == Types::MutationOperationModeEnum.enum[:remove]
          assignee_ids -= user_ids
        else
          assignee_ids |= user_ids
        end

        ::MergeRequests::UpdateService.new(project, current_user, assignee_ids: assignee_ids)
          .execute(merge_request)

        {
          merge_request: merge_request,
          errors: merge_request.errors.full_messages
        }
      end
    end
  end
end

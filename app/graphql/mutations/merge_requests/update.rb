# frozen_string_literal: true

module Mutations
  module MergeRequests
    class Update < Base
      graphql_name 'MergeRequestUpdate'

      description 'Update attributes of a merge request'

      argument :title, GraphQL::STRING_TYPE,
               required: false,
               description: copy_field_description(Types::MergeRequestType, :title)

      argument :target_branch, GraphQL::STRING_TYPE,
               required: false,
               description: copy_field_description(Types::MergeRequestType, :target_branch)

      argument :description, GraphQL::STRING_TYPE,
               required: false,
               description: copy_field_description(Types::MergeRequestType, :description)

      argument :state, ::Types::MergeRequestStateEventEnum,
               required: false,
               as: :state_event,
               description: 'The action to perform to change the state.'

      def resolve(project_path:, iid:, **args)
        merge_request = authorized_find!(project_path: project_path, iid: iid)
        attributes = args.compact

        ::MergeRequests::UpdateService
          .new(project: merge_request.project, current_user: current_user, params: attributes)
          .execute(merge_request)

        errors = errors_on_object(merge_request)

        {
          merge_request: merge_request.reset,
          errors: errors
        }
      end
    end
  end
end

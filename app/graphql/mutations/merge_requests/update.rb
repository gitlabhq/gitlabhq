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

      def resolve(args)
        merge_request = authorized_find!(args.slice(:project_path, :iid))
        attributes = args.slice(:title, :description, :target_branch).compact

        ::MergeRequests::UpdateService
          .new(merge_request.project, current_user, attributes)
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

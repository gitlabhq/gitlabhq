# frozen_string_literal: true

module Mutations
  module MergeRequests
    class Create < BaseMutation
      include ResolvesProject

      graphql_name 'MergeRequestCreate'

      argument :project_path, GraphQL::ID_TYPE,
               required: true,
               description: 'Project full path the merge request is associated with'

      argument :title, GraphQL::STRING_TYPE,
               required: true,
               description: copy_field_description(Types::MergeRequestType, :title)

      argument :source_branch, GraphQL::STRING_TYPE,
               required: true,
               description: copy_field_description(Types::MergeRequestType, :source_branch)

      argument :target_branch, GraphQL::STRING_TYPE,
               required: true,
               description: copy_field_description(Types::MergeRequestType, :target_branch)

      argument :description, GraphQL::STRING_TYPE,
               required: false,
               description: copy_field_description(Types::MergeRequestType, :description)

      field :merge_request,
            Types::MergeRequestType,
            null: true,
            description: 'The merge request after mutation'

      authorize :create_merge_request_from

      def resolve(project_path:, title:, source_branch:, target_branch:, description: nil)
        project = authorized_find!(full_path: project_path)

        attributes = {
          title: title,
          source_branch: source_branch,
          target_branch: target_branch,
          author_id: current_user.id,
          description: description
        }

        merge_request = ::MergeRequests::CreateService.new(project, current_user, attributes).execute

        {
          merge_request: merge_request.valid? ? merge_request : nil,
          errors: errors_on_object(merge_request)
        }
      end

      private

      def find_object(full_path:)
        resolve_project(full_path: full_path)
      end
    end
  end
end

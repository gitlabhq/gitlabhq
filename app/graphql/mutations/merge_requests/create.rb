# frozen_string_literal: true

module Mutations
  module MergeRequests
    class Create < BaseMutation
      graphql_name 'MergeRequestCreate'

      include FindsProject

      argument :project_path, GraphQL::Types::ID,
        required: true,
        description: 'Project full path the merge request is associated with.'

      argument :title, GraphQL::Types::String,
        required: true,
        description: copy_field_description(Types::MergeRequestType, :title)

      argument :source_branch, GraphQL::Types::String,
        required: true,
        description: copy_field_description(Types::MergeRequestType, :source_branch)

      argument :target_branch, GraphQL::Types::String,
        required: true,
        description: copy_field_description(Types::MergeRequestType, :target_branch)

      argument :description, GraphQL::Types::String,
        required: false,
        description: copy_field_description(Types::MergeRequestType, :description)

      argument :labels, [GraphQL::Types::String],
        required: false,
        description: copy_field_description(Types::MergeRequestType, :labels)

      argument :merge_after, ::Types::TimeType,
        required: false,
        description: copy_field_description(Types::MergeRequestType, :merge_after)

      argument :remove_source_branch, GraphQL::Types::Boolean,
        required: false,
        description: copy_field_description(Types::MergeRequestType, :should_remove_source_branch)

      field :merge_request,
        Types::MergeRequestType,
        null: true,
        description: 'Merge request after mutation.'

      authorize :create_merge_request_from

      def resolve(project_path:, **attributes)
        project = authorized_find!(project_path)
        params = parse_arguments(attributes)

        merge_request = ::MergeRequests::CreateService.new(
          project: project,
          current_user: current_user,
          params: params
        ).execute

        {
          merge_request: merge_request.valid? ? merge_request : nil,
          errors: errors_on_object(merge_request)
        }
      end

      private

      def parse_arguments(args)
        args = args.merge(author_id: current_user.id)

        args[:force_remove_source_branch] = args.delete(:remove_source_branch) if args.key?(:remove_source_branch)

        args.compact
      end
    end
  end
end

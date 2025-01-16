# frozen_string_literal: true

module Mutations
  module WorkItems
    class AddClosingMergeRequest < BaseMutation
      graphql_name 'WorkItemAddClosingMergeRequest'
      description 'Adds a closing merge request to a work item'

      authorize :update_work_item

      argument :context_namespace_path, GraphQL::Types::ID,
        required: false,
        description: 'Full path of the context namespace (project or group). Only project full paths are used to ' \
          'find a merge request using a short reference syntax like `!1`. Ignored for full references and URLs. ' \
          'Defaults to the namespace of the work item if not provided.'
      argument :id, ::Types::GlobalIDType[::WorkItem],
        required: true,
        description: 'Global ID of the work item.'
      argument :merge_request_reference, GraphQL::Types::String,
        required: true,
        description: 'Merge request reference (short, full or URL). Example: ' \
          '`!1`, `project_full_path!1` or `https://gitlab.com/gitlab-org/gitlab/-/merge_requests/1`.'

      field :closing_merge_request,
        ::Types::WorkItems::ClosingMergeRequestType,
        null: true,
        description: 'Closing merge request added to the work item.'
      field :work_item, ::Types::WorkItemType,
        null: true,
        description: 'Work item with new closing merge requests.'

      def resolve(id:, merge_request_reference:, context_namespace_path: nil)
        work_item = authorized_find!(id: id)

        result = ::WorkItems::ClosingMergeRequests::CreateService.new(
          current_user: current_user,
          work_item: work_item,
          merge_request_reference: merge_request_reference,
          namespace_path: context_namespace_path
        ).execute

        {
          work_item: result.success? ? work_item : nil,
          closing_merge_request: result.success? ? result[:merge_request_closing_issue] : nil,
          errors: result.errors
        }
      rescue ::WorkItems::ClosingMergeRequests::CreateService::ResourceNotAvailable
        raise_resource_not_available_error!
      end
    end
  end
end

# frozen_string_literal: true

module Types
  module MergeRequests
    class WorkItemRelationType < BaseObject
      graphql_name 'MergeRequestWorkItemRelation'
      description 'A relation between a merge request and a work item'

      authorize :read_merge_request_closing_issue
      authorize_granular_token permissions: :read_merge_request, boundary: :project, boundary_type: :project

      field :id, ::Types::GlobalIDType[::MergeRequestsClosingIssues],
        null: false,
        description: 'Global ID of the merge request to work item relation.'

      field :link_type, ::Types::MergeRequests::WorkItemLinkTypeEnum,
        null: false,
        description: 'Type of relationship between the merge request and the work item.'

      field :from_mr_description, GraphQL::Types::Boolean,
        null: false,
        description: 'Whether the relation was derived from a closing pattern in the merge request description.'

      field :work_item, ::Types::WorkItemType,
        null: true,
        description: 'Related work item.'

      def work_item
        ::Gitlab::Graphql::Loaders::BatchModelLoader.new(::WorkItem, object.issue_id).find
      end
    end
  end
end

# frozen_string_literal: true

module Types
  module WorkItems
    class ClosingMergeRequestType < BaseObject
      graphql_name 'WorkItemClosingMergeRequest'

      authorize :read_merge_request_closing_issue

      field :from_mr_description, GraphQL::Types::Boolean,
        null: false,
        description: 'Whether this merge request link was created by referencing the work item on the ' \
          'merge request description, using the closing pattern.'
      field :id, ::Types::GlobalIDType[::MergeRequestsClosingIssues],
        null: false,
        description: 'Global ID of the closing merge request association.'
      field :merge_request, ::Types::MergeRequestType,
        null: true,
        description: 'Related merge request.'
    end
  end
end

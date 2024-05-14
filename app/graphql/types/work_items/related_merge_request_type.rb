# frozen_string_literal: true

module Types
  module WorkItems
    class RelatedMergeRequestType < BaseObject
      graphql_name 'WorkItemRelatedMergeRequest'

      authorize :read_merge_request_closing_issue

      field :closes_work_item, GraphQL::Types::Boolean,
        null: false,
        description: 'Whether the related merge request will close the work item when it is merged.'
      field :merge_request, Types::MergeRequestType,
        null: true,
        description: 'Related merge request.'
    end
  end
end

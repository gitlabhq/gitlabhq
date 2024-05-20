# frozen_string_literal: true

module Types
  module WorkItems
    class RelatedMergeRequestType < BaseObject
      graphql_name 'WorkItemRelatedMergeRequest'

      authorize :read_merge_request_closing_issue

      field :merge_request, Types::MergeRequestType,
        null: true,
        description: 'Related merge request.'
    end
  end
end

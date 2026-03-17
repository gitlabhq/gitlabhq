# frozen_string_literal: true

module Types
  module MergeRequests
    # rubocop:disable Graphql/AuthorizeTypes -- authorized by resolver
    class LinkedWorkItemType < BaseObject
      graphql_name 'MergeRequestLinkedWorkItem'
      description 'A work item linked to a merge request'

      field :link_type, WorkItemLinkTypeEnum,
        null: false,
        description: 'Type of relationship between the merge request and work item.'

      field :work_item, ::Types::WorkItemType,
        null: true,
        description: 'Linked work item.'

      field :external_issue, ::Types::MergeRequests::ExternalIssueType,
        null: true,
        description: 'Linked external issue.'
    end
    # rubocop:enable Graphql/AuthorizeTypes
  end
end

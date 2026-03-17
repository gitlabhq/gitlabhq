# frozen_string_literal: true

module Types
  module MergeRequests
    class WorkItemLinkTypeEnum < BaseEnum
      graphql_name 'MergeRequestWorkItemLinkType'
      description 'Type of relationship between a merge request and a work item'

      value 'CLOSES',
        description: 'Work item will be closed when the merge request is merged.',
        value: 'closes'
      value 'MENTIONED',
        description: 'Work item is mentioned in the merge request but will not be closed.',
        value: 'mentioned'
    end
  end
end

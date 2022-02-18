# frozen_string_literal: true

module Types
  class WorkItemStateEnum < BaseEnum
    graphql_name 'WorkItemState'
    description 'State of a GitLab work item'

    value 'OPEN', 'In open state.', value: 'opened'
    value 'CLOSED', 'In closed state.', value: 'closed'
  end
end

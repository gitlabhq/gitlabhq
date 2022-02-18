# frozen_string_literal: true

module Types
  module WorkItems
    class StateEventEnum < BaseEnum
      graphql_name 'WorkItemStateEvent'
      description 'Values for work item state events'

      value 'REOPEN', 'Reopens the work item.', value: 'reopen'
      value 'CLOSE', 'Closes the work item.', value: 'close'
    end
  end
end

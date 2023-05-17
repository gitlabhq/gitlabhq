# frozen_string_literal: true

module Types
  module WorkItems
    class TodoUpdateActionEnum < BaseEnum
      graphql_name 'WorkItemTodoUpdateAction'
      description 'Values for work item to-do update enum'

      value 'MARK_AS_DONE', 'Marks the to-do as done.', value: 'mark_as_done'
      value 'ADD', 'Adds the to-do.', value: 'add'
    end
  end
end

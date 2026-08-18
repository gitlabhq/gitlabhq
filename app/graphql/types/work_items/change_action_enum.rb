# frozen_string_literal: true

module Types
  module WorkItems
    class ChangeActionEnum < BaseEnum
      graphql_name 'WorkItemChangeAction'
      description 'Action that triggered a work item change event.'

      value 'CREATED', 'Work item was created.', value: :created, experiment: { milestone: '19.3' }
      value 'UPDATED', 'Work item was updated.', value: :updated, experiment: { milestone: '19.3' }
      value 'DELETED', 'Work item was deleted.', value: :deleted, experiment: { milestone: '19.3' }
    end
  end
end

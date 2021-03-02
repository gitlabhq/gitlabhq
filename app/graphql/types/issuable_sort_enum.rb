# frozen_string_literal: true

module Types
  class IssuableSortEnum < SortEnum
    graphql_name 'IssuableSort'
    description 'Values for sorting issuables'

    value 'PRIORITY_ASC', 'Priority by ascending order.', value: :priority_asc
    value 'PRIORITY_DESC', 'Priority by descending order.', value: :priority_desc
    value 'LABEL_PRIORITY_ASC', 'Label priority by ascending order.', value: :label_priority_asc
    value 'LABEL_PRIORITY_DESC', 'Label priority by descending order.', value: :label_priority_desc
    value 'MILESTONE_DUE_ASC', 'Milestone due date by ascending order.', value: :milestone_due_asc
    value 'MILESTONE_DUE_DESC', 'Milestone due date by descending order.', value: :milestone_due_desc
  end
end

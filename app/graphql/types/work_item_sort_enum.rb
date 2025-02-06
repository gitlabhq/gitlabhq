# frozen_string_literal: true

module Types
  class WorkItemSortEnum < SortEnum
    graphql_name 'WorkItemSort'
    description 'Values for sorting work items'

    value 'TITLE_ASC', 'Title by ascending order.', value: :title_asc
    value 'TITLE_DESC', 'Title by descending order.', value: :title_desc

    value 'START_DATE_ASC', 'Start date of the corresponding WorkItemWidgetStartAndDueDate by ascending order.',
      value: :start_date_asc, experiment: { milestone: '17.9' }
    value 'START_DATE_DESC', 'Start date of the corresponding WorkItemWidgetStartAndDueDate by descending order.',
      value: :start_date_desc, experiment: { milestone: '17.9' }
    value 'DUE_DATE_ASC', 'Due date of the corresponding WorkItemWidgetStartAndDueDate by ascending order.',
      value: :due_date_asc, experiment: { milestone: '17.9' }
    value 'DUE_DATE_DESC', 'Due date of the corresponding WorkItemWidgetStartAndDueDate by descending order.',
      value: :due_date_desc, experiment: { milestone: '17.9' }
  end
end

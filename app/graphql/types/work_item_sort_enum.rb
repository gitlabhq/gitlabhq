# frozen_string_literal: true

module Types
  class WorkItemSortEnum < SortEnum
    graphql_name 'WorkItemSort'
    description 'Values for sorting work items'

    value 'TITLE_ASC', 'Title by ascending order.', value: :title_asc
    value 'TITLE_DESC', 'Title by descending order.', value: :title_desc
  end
end

# frozen_string_literal: true

module Types
  class TodoSortEnum < SortEnum
    graphql_name 'TodoSort'
    description 'Sort options for todos.'

    value 'LABEL_PRIORITY_ASC', 'By label priority in ascending order.', value: :label_priority_asc
    value 'LABEL_PRIORITY_DESC', 'By label priority in descending order.', value: :label_priority_desc
  end
end

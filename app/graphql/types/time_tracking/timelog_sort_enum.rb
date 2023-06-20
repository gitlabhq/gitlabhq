# frozen_string_literal: true

module Types
  module TimeTracking
    class TimelogSortEnum < SortEnum
      graphql_name 'TimelogSort'
      description 'Values for sorting timelogs'

      value 'SPENT_AT_ASC', 'Spent at ascending order.', value: :spent_at_asc
      value 'SPENT_AT_DESC', 'Spent at descending order.', value: :spent_at_desc
      value 'TIME_SPENT_ASC', 'Time spent ascending order.', value: :time_spent_asc
      value 'TIME_SPENT_DESC', 'Time spent descending order.', value: :time_spent_desc
    end
  end
end

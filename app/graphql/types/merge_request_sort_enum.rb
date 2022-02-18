# frozen_string_literal: true

module Types
  class MergeRequestSortEnum < IssuableSortEnum
    graphql_name 'MergeRequestSort'
    description 'Values for sorting merge requests'

    value 'MERGED_AT_ASC', 'Merge time by ascending order.', value: :merged_at_asc
    value 'MERGED_AT_DESC', 'Merge time by descending order.', value: :merged_at_desc
    value 'CLOSED_AT_ASC', 'Closed time by ascending order.', value: :closed_at_asc
    value 'CLOSED_AT_DESC', 'Closed time by descending order.', value: :closed_at_desc
    value 'TITLE_ASC', 'Title by ascending order.', value: :title_asc
    value 'TITLE_DESC', 'Title by descending order.', value: :title_desc
  end
end

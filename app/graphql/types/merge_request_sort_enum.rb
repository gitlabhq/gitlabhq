# frozen_string_literal: true

module Types
  class MergeRequestSortEnum < IssuableSortEnum
    graphql_name 'MergeRequestSort'
    description 'Values for sorting merge requests'

    value 'MERGED_AT_ASC', 'Merge time by ascending order.', value: :merged_at_asc
    value 'MERGED_AT_DESC', 'Merge time by descending order.', value: :merged_at_desc
  end
end

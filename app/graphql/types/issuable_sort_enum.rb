# frozen_string_literal: true

module Types
  class IssuableSortEnum < SortEnum
    graphql_name 'IssuableSort'
    description 'Values for sorting issuables'

    value 'PRIORITY_ASC', 'Priority by ascending order', value: :priority_asc
    value 'PRIORITY_DESC', 'Priority by descending order', value: :priority_desc
  end
end

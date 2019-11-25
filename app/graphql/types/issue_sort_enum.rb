# frozen_string_literal: true

module Types
  class IssueSortEnum < IssuableSortEnum
    graphql_name 'IssueSort'
    description 'Values for sorting issues'

    value 'DUE_DATE_ASC', 'Due date by ascending order', value: 'due_date_asc'
    value 'DUE_DATE_DESC', 'Due date by descending order', value: 'due_date_desc'
    value 'RELATIVE_POSITION_ASC', 'Relative position by ascending order', value: 'relative_position_asc'
  end
end

Types::IssueSortEnum.prepend_if_ee('::EE::Types::IssueSortEnum')

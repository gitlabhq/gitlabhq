# frozen_string_literal: true

module Types
  class SortEnum < BaseEnum
    graphql_name 'Sort'
    description 'Common sort values'

    # Deprecated, as we prefer uppercase enums
    # https://gitlab.com/groups/gitlab-org/-/epics/1838
    value 'updated_desc', 'Updated at descending order.',
      value: :updated_desc,
      deprecated: {
        reason: :renamed,
        replacement: 'UPDATED_DESC',
        milestone: '13.5'
      }
    value 'updated_asc', 'Updated at ascending order.',
      value: :updated_asc,
      deprecated: {
        reason: :renamed,
        replacement: 'UPDATED_ASC',
        milestone: '13.5'
      }
    value 'created_desc', 'Created at descending order.',
      value: :created_desc,
      deprecated: {
        reason: :renamed,
        replacement: 'CREATED_DESC',
        milestone: '13.5'
      }
    value 'created_asc', 'Created at ascending order.',
      value: :created_asc,
      deprecated: {
        reason: :renamed,
        replacement: 'CREATED_ASC',
        milestone: '13.5'
      }

    value 'UPDATED_DESC', 'Updated at descending order.', value: :updated_desc
    value 'UPDATED_ASC', 'Updated at ascending order.', value: :updated_asc
    value 'CREATED_DESC', 'Created at descending order.', value: :created_desc
    value 'CREATED_ASC', 'Created at ascending order.', value: :created_asc
  end
end

# frozen_string_literal: true

module Types
  class SortDirectionEnum < BaseEnum
    graphql_name 'SortDirectionEnum'
    description 'Values for sort direction'

    value 'ASC', 'Ascending order.', value: 'asc'
    value 'DESC', 'Descending order.', value: 'desc'
  end
end

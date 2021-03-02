# frozen_string_literal: true

module Types
  # Not inheriting from Types::SortEnum since we only want
  # to implement a subset of the sort values it defines.
  class ReleaseSortEnum < BaseEnum
    graphql_name 'ReleaseSort'
    description 'Values for sorting releases'

    # Borrowed from Types::SortEnum
    # These values/descriptions should stay in-sync as much as possible.
    value 'CREATED_DESC', 'Created at descending order.', value: :created_desc
    value 'CREATED_ASC', 'Created at ascending order.', value: :created_asc

    value 'RELEASED_AT_DESC', 'Released at by descending order.', value: :released_at_desc
    value 'RELEASED_AT_ASC', 'Released at by ascending order.', value: :released_at_asc
  end
end

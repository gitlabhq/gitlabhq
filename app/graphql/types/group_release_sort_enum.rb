# frozen_string_literal: true

module Types
  # Not inheriting from Types::SortEnum since we only want
  # to implement a subset of the sort values it defines.
  class GroupReleaseSortEnum < BaseEnum
    graphql_name 'GroupReleaseSort'
    description 'Values for sorting releases belonging to a group'

    # Borrowed from Types::ReleaseSortEnum and Types::SortEnum
    # These values/descriptions should stay in-sync as much as possible.
    value 'RELEASED_AT_DESC', 'Released at by descending order.', value: :released_at_desc
    value 'RELEASED_AT_ASC', 'Released at by ascending order.', value: :released_at_asc
  end
end

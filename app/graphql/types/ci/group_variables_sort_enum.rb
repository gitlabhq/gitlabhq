# frozen_string_literal: true

module Types
  module Ci
    # Not inheriting from Types::SortEnum since we only want
    # to implement a subset of the sort values it defines.
    class GroupVariablesSortEnum < BaseEnum
      graphql_name 'CiGroupVariablesSort'
      description 'Values for sorting inherited variables'

      # Borrowed from Types::SortEnum
      # These values/descriptions should stay in-sync as much as possible.
      value 'CREATED_DESC', 'Created at descending order.', value: :created_desc
      value 'CREATED_ASC', 'Created at ascending order.', value: :created_asc

      value 'KEY_DESC', 'Key by descending order.', value: :key_desc
      value 'KEY_ASC', 'Key by ascending order.', value: :key_asc
    end
  end
end

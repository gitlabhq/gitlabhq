# frozen_string_literal: true

module Types
  module Ci
    class VariableSortEnum < BaseEnum
      graphql_name 'CiVariableSort'
      description 'Values for sorting variables'

      value 'KEY_ASC', 'Sorted by key in ascending order.', value: :key_asc
      value 'KEY_DESC', 'Sorted by key in descending order.', value: :key_desc
    end
  end
end

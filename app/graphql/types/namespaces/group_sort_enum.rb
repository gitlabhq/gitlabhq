# frozen_string_literal: true

module Types
  module Namespaces
    class GroupSortEnum < BaseEnum
      graphql_name 'GroupSort'
      description 'Values for sorting groups'

      value 'SIMILARITY',
        'Most similar to the search query.',
        value: :similarity
    end
  end
end

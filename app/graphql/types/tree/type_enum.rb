# frozen_string_literal: true

module Types
  module Tree
    class TypeEnum < BaseEnum
      graphql_name 'EntryType'
      description 'Type of a tree entry'

      value 'tree', value: :tree
      value 'blob', value: :blob
      value 'commit', value: :commit
    end
  end
end

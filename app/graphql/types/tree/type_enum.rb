# frozen_string_literal: true

module Types
  module Tree
    class TypeEnum < BaseEnum
      graphql_name 'EntryType'
      description 'Type of a tree entry'

      value 'tree', description: 'Directory tree type.', value: :tree
      value 'blob', description: 'File tree type.', value: :blob
      value 'commit', description: 'Commit tree type.', value: :commit
    end
  end
end

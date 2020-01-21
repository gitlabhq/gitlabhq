# frozen_string_literal: true
module Types
  module Tree
    module EntryType
      include Types::BaseInterface

      field :id, GraphQL::ID_TYPE, null: false,
            description: 'ID of the entry'
      field :sha, GraphQL::STRING_TYPE, null: false,
            description: 'Last commit sha for the entry', method: :id
      field :name, GraphQL::STRING_TYPE, null: false,
            description: 'Name of the entry'
      field :type, Tree::TypeEnum, null: false,
            description: 'Type of tree entry'
      field :path, GraphQL::STRING_TYPE, null: false,
            description: 'Path of the entry'
      field :flat_path, GraphQL::STRING_TYPE, null: false,
            description: 'Flat path of the entry'
    end
  end
end

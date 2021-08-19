# frozen_string_literal: true
module Types
  module Tree
    module EntryType
      include Types::BaseInterface

      field :id, GraphQL::Types::ID, null: false,
            description: 'ID of the entry.'
      field :sha, GraphQL::Types::String, null: false,
            description: 'Last commit SHA for the entry.', method: :id
      field :name, GraphQL::Types::String, null: false,
            description: 'Name of the entry.'
      field :type, Tree::TypeEnum, null: false,
            description: 'Type of tree entry.'
      field :path, GraphQL::Types::String, null: false,
            description: 'Path of the entry.'
      field :flat_path, GraphQL::Types::String, null: false,
            description: 'Flat path of the entry.'
    end
  end
end

# frozen_string_literal: true
module Types
  module Tree
    module EntryType
      include Types::BaseInterface

      field :id, GraphQL::ID_TYPE, null: false
      field :name, GraphQL::STRING_TYPE, null: false
      field :type, Tree::TypeEnum, null: false
      field :path, GraphQL::STRING_TYPE, null: false
      field :flat_path, GraphQL::STRING_TYPE, null: false
    end
  end
end

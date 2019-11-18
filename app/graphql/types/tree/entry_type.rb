# frozen_string_literal: true
module Types
  module Tree
    module EntryType
      include Types::BaseInterface

      field :id, GraphQL::ID_TYPE, null: false # rubocop:disable Graphql/Descriptions
      field :sha, GraphQL::STRING_TYPE, null: false, description: "Last commit sha for entry", method: :id
      field :name, GraphQL::STRING_TYPE, null: false # rubocop:disable Graphql/Descriptions
      field :type, Tree::TypeEnum, null: false # rubocop:disable Graphql/Descriptions
      field :path, GraphQL::STRING_TYPE, null: false # rubocop:disable Graphql/Descriptions
      field :flat_path, GraphQL::STRING_TYPE, null: false # rubocop:disable Graphql/Descriptions
    end
  end
end

# frozen_string_literal: true

module Types
  class BoardType < BaseObject
    graphql_name 'Board'
    description 'Represents a project or group board'

    authorize :read_board

    field :id, type: GraphQL::ID_TYPE, null: false,
          description: 'ID (global ID) of the board'
    field :name, type: GraphQL::STRING_TYPE, null: true,
          description: 'Name of the board'

    field :lists,
          Types::BoardListType.connection_type,
          null: true,
          description: 'Lists of the board',
          resolver: Resolvers::BoardListsResolver,
          extras: [:lookahead]
  end
end

Types::BoardType.prepend_if_ee('::EE::Types::BoardType')

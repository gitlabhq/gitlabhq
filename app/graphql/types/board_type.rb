# frozen_string_literal: true

module Types
  class BoardType < BaseObject
    graphql_name 'Board'
    description 'Represents a project or group issue board'
    accepts ::Board
    authorize :read_issue_board

    present_using BoardPresenter

    field :id, type: GraphQL::ID_TYPE, null: false,
          description: 'ID (global ID) of the board.'
    field :name, type: GraphQL::STRING_TYPE, null: true,
          description: 'Name of the board.'

    field :hide_backlog_list, type: GraphQL::BOOLEAN_TYPE, null: true,
          description: 'Whether or not backlog list is hidden.'

    field :hide_closed_list, type: GraphQL::BOOLEAN_TYPE, null: true,
          description: 'Whether or not closed list is hidden.'

    field :created_at, Types::TimeType, null: false,
          description: 'Timestamp of when the board was created.'

    field :updated_at, Types::TimeType, null: false,
          description: 'Timestamp of when the board was last updated.'

    field :lists,
          Types::BoardListType.connection_type,
          null: true,
          description: 'Lists of the board.',
          resolver: Resolvers::BoardListsResolver,
          extras: [:lookahead]

    field :web_path, GraphQL::STRING_TYPE, null: false,
          description: 'Web path of the board.'

    field :web_url, GraphQL::STRING_TYPE, null: false,
          description: 'Web URL of the board.'
  end
end

Types::BoardType.prepend_mod_with('Types::BoardType')

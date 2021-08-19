# frozen_string_literal: true

module Types
  class BoardType < BaseObject
    graphql_name 'Board'
    description 'Represents a project or group issue board'
    accepts ::Board
    authorize :read_issue_board

    present_using BoardPresenter

    field :id, type: GraphQL::Types::ID, null: false,
          description: 'ID (global ID) of the board.'
    field :name, type: GraphQL::Types::String, null: true,
          description: 'Name of the board.'

    field :hide_backlog_list, type: GraphQL::Types::Boolean, null: true,
          description: 'Whether or not backlog list is hidden.'

    field :hide_closed_list, type: GraphQL::Types::Boolean, null: true,
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

    field :web_path, GraphQL::Types::String, null: false,
          description: 'Web path of the board.'

    field :web_url, GraphQL::Types::String, null: false,
          description: 'Web URL of the board.'
  end
end

Types::BoardType.prepend_mod_with('Types::BoardType')

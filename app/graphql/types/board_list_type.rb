# frozen_string_literal: true

module Types
  # rubocop: disable Graphql/AuthorizeTypes
  class BoardListType < BaseObject
    graphql_name 'BoardList'
    description 'Represents a list for an issue board'

    field :id, GraphQL::ID_TYPE, null: false,
          description: 'ID (global ID) of the list'
    field :title, GraphQL::STRING_TYPE, null: false,
          description: 'Title of the list'
    field :list_type, GraphQL::STRING_TYPE, null: false,
          description: 'Type of the list'
    field :position, GraphQL::INT_TYPE, null: true,
          description: 'Position of list within the board'
    field :label, Types::LabelType, null: true,
          description: 'Label of the list'
    field :collapsed, GraphQL::BOOLEAN_TYPE, null: true,
          description: 'Indicates if list is collapsed for this user',
          resolve: -> (list, _args, ctx) { list.collapsed?(ctx[:current_user]) }
  end
  # rubocop: enable Graphql/AuthorizeTypes
end

Types::BoardListType.prepend_if_ee('::EE::Types::BoardListType')

# frozen_string_literal: true

module Types
  # rubocop: disable Graphql/AuthorizeTypes
  class BoardListType < BaseObject
    include Gitlab::Utils::StrongMemoize

    graphql_name 'BoardList'
    description 'Represents a list for an issue board'

    alias_method :list, :object

    field :id, GraphQL::Types::ID, null: false,
          description: 'ID (global ID) of the list.'
    field :title, GraphQL::Types::String, null: false,
          description: 'Title of the list.'
    field :list_type, GraphQL::Types::String, null: false,
          description: 'Type of the list.'
    field :position, GraphQL::Types::Int, null: true,
          description: 'Position of list within the board.'
    field :label, Types::LabelType, null: true,
          description: 'Label of the list.'
    field :collapsed, GraphQL::Types::Boolean, null: true,
          description: 'Indicates if the list is collapsed for this user.'
    field :issues_count, GraphQL::Types::Int, null: true,
          description: 'Count of issues in the list.'

    field :issues, ::Types::IssueType.connection_type, null: true,
          description: 'Board issues.',
          resolver: ::Resolvers::BoardListIssuesResolver

    def issues_count
      metadata[:size]
    end

    def collapsed
      object.collapsed?(context[:current_user])
    end

    def metadata
      strong_memoize(:metadata) do
        params = (context[:issue_filters] || {}).merge(board_id: list.board_id, id: list.id)

        ::Boards::Issues::ListService
          .new(list.board.resource_parent, current_user, params)
          .metadata
      end
    end
  end
  # rubocop: enable Graphql/AuthorizeTypes
end

Types::BoardListType.prepend_mod_with('Types::BoardListType')

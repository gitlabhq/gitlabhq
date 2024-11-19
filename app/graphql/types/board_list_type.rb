# frozen_string_literal: true

module Types
  # rubocop: disable Graphql/AuthorizeTypes
  class BoardListType < BaseObject
    graphql_name 'BoardList'
    description 'Represents a list for an issue board'

    include Gitlab::Utils::StrongMemoize

    alias_method :list, :object

    field :id, GraphQL::Types::ID,
      null: false,
      description: 'ID (global ID) of the list.'

    field :collapsed, GraphQL::Types::Boolean, null: true,
      description: 'Indicates if the list is collapsed for the user.'
    field :issues_count, GraphQL::Types::Int, null: true,
      description: 'Count of issues in the list.'
    field :label, Types::LabelType, null: true,
      description: 'Label of the list.'
    field :list_type, GraphQL::Types::String, null: false,
      description: 'Type of the list.'
    field :position, GraphQL::Types::Int, null: true,
      description: 'Position of list within the board.'
    field :title, GraphQL::Types::String, null: false,
      description: 'Title of the list.'

    field :issues,
      ::Types::IssueType.connection_type,
      null: true,
      description: 'Board issues.',
      late_extensions: [Gitlab::Graphql::Board::IssuesConnectionExtension],
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

    # board lists have a data dependency on label - so we batch load them here
    def title
      BatchLoader::GraphQL.for(object).batch do |lists, callback|
        ActiveRecord::Associations::Preloader.new(records: lists, associations: :label).call

        # all list titles are preloaded at this point
        lists.each { |list| callback.call(list, list.title) }
      end
    end
  end
  # rubocop: enable Graphql/AuthorizeTypes
end

Types::BoardListType.prepend_mod_with('Types::BoardListType')

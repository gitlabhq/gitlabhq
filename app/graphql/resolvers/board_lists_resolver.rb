# frozen_string_literal: true

module Resolvers
  class BoardListsResolver < BaseResolver
    include Gitlab::Graphql::Authorize::AuthorizeResource

    type Types::BoardListType, null: true

    alias_method :board, :object

    def resolve(lookahead: nil)
      authorize!(board)

      lists = board_lists

      if load_preferences?(lookahead)
        List.preload_preferences_for_user(lists, context[:current_user])
      end

      Gitlab::Graphql::Pagination::OffsetActiveRecordRelationConnection.new(lists)
    end

    private

    def board_lists
      service = Boards::Lists::ListService.new(board.resource_parent, context[:current_user])
      service.execute(board, create_default_lists: false)
    end

    def authorized_resource?(board)
      Ability.allowed?(context[:current_user], :read_list, board)
    end

    def load_preferences?(lookahead)
      lookahead&.selection(:edges)&.selection(:node)&.selects?(:collapsed)
    end
  end
end

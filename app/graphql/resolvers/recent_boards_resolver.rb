# frozen_string_literal: true

module Resolvers
  class RecentBoardsResolver < BaseResolver
    type Types::BoardType, null: true

    def resolve
      parent = object.respond_to?(:sync) ? object.sync : object
      return Board.none unless parent

      recent_visits =
        ::Boards::VisitsFinder.new(parent, current_user).latest(Board::RECENT_BOARDS_SIZE)

      recent_visits&.map(&:board) || []
    end
  end
end

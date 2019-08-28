# frozen_string_literal: true

module Boards
  module Lists
    class ListService < Boards::BaseService
      def execute(board)
        board.lists.create(list_type: :backlog) unless board.lists.backlog.exists?

        board.lists.preload_associations(current_user)
      end
    end
  end
end

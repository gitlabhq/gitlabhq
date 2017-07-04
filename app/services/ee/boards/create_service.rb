module EE
  module Boards
    class CreateService < BaseService
      def execute
        return nil unless can_create_board?

        board = project.boards.create(params)

        if board.persisted?
          board.lists.create(list_type: :backlog)
          board.lists.create(list_type: :closed)
        end

        board
      end

      def can_create_board?
        project.feature_available?(:multiple_issue_boards) || project.boards.size < 1
      end
    end
  end
end

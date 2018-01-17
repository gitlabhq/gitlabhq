module Boards
  class CreateService < Boards::BaseService
    prepend EE::Boards::CreateService

    def execute
      create_board! if can_create_board?
    end

    private

    def can_create_board?
      parent.boards.size == 0
    end

    def create_board!
      set_assignee
      set_milestone

      board = parent.boards.create(params)

      if board.persisted?
        board.lists.create(list_type: :backlog)
        board.lists.create(list_type: :closed)
      end

      board
    end
  end
end

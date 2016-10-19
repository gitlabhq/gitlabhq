module Boards
  class CreateService < BaseService
    def execute
      board = project.boards.create(params)

      if board.persisted?
        board.lists.create(list_type: :backlog)
        board.lists.create(list_type: :done)
      end

      board
    end
  end
end

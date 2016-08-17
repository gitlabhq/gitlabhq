module Boards
  class CreateService < Boards::BaseService
    def execute
      create_board! unless project.board.present?
      project.board
    end

    private

    def create_board!
      project.create_board
      project.board.lists.create(list_type: :backlog)
      project.board.lists.create(list_type: :done)
    end
  end
end

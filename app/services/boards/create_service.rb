# frozen_string_literal: true

module Boards
  class CreateService < Boards::BaseService
    def execute
      unless can_create_board?
        return ServiceResponse.error(message: "You don't have the permission to create a board for this resource.")
      end

      create_board!
    end

    private

    def can_create_board?
      parent.boards.empty? || parent.multiple_issue_boards_available?
    end

    def create_board!
      board = parent.boards.create(params)

      unless board.persisted?
        return ServiceResponse.error(message: "There was an error when creating a board.", payload: board)
      end

      board.tap do |created_board|
        created_board.lists.create(list_type: :backlog)
        created_board.lists.create(list_type: :closed)
      end

      ServiceResponse.success(payload: board)
    end
  end
end

Boards::CreateService.prepend_if_ee('EE::Boards::CreateService')

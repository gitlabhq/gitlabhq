# frozen_string_literal: true

module Boards
  class ListService < Boards::BaseService
    def execute(create_default_board: true)
      create_board! if create_default_board && parent.boards.empty?

      if parent.multiple_issue_boards_available?
        boards
      else
        # When multiple issue boards are not available
        # a user is only allowed to view the default shown board
        first_board
      end
    end

    private

    def boards
      parent.boards.order_by_name_asc
    end

    def first_board
      parent.boards.first_board
    end

    def create_board!
      Boards::CreateService.new(parent, current_user).execute
    end
  end
end

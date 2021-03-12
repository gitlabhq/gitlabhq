# frozen_string_literal: true

module Boards
  class BoardsFinder < Boards::BaseService
    def execute
      find_boards
    end

    private

    def boards
      parent.boards.order_by_name_asc
    end

    def first_board
      parent.boards.first_board
    end

    def find_boards
      found =
        if parent.multiple_issue_boards_available?
          boards
        else
          # When multiple issue boards are not available
          # a user is only allowed to view the default shown board
          first_board
        end

      params[:board_id].present? ? [found.find(params[:board_id])] : found
    end
  end
end

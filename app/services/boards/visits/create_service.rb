# frozen_string_literal: true

module Boards
  module Visits
    class CreateService < Boards::BaseService
      def execute(board)
        return unless current_user && Gitlab::Database.read_write?
        return unless board.is_a?(Board) # other board types do not support board visits yet

        if parent.is_a?(Group)
          BoardGroupRecentVisit.visited!(current_user, board)
        else
          BoardProjectRecentVisit.visited!(current_user, board)
        end
      end
    end
  end
end

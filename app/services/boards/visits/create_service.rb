# frozen_string_literal: true

module Boards
  module Visits
    class CreateService < Boards::BaseService
      def execute(board)
        return unless current_user && Gitlab::Database.main.read_write?
        return unless board

        model.visited!(current_user, board)
      end

      private

      def model
        return BoardGroupRecentVisit if parent.is_a?(Group)

        BoardProjectRecentVisit
      end
    end
  end
end

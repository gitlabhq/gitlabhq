module Boards
  module Issues
    class CreateService < BaseService
      def execute
        create_issue(params.merge(label_ids: [list.label_id]))
      end

      private

      def board
        @board ||= project.boards.find(params.delete(:board_id))
      end

      def list
        @list ||= board.lists.find(params.delete(:list_id))
      end

      def create_issue(params)
        ::Issues::CreateService.new(project, current_user, params).execute
      end
    end
  end
end

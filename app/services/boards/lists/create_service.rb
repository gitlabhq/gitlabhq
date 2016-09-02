module Boards
  module Lists
    class CreateService < Boards::BaseService
      def execute
        List.transaction do
          label    = project.labels.find(params[:label_id])
          position = next_position

          create_list(label, position)
        end
      end

      private

      def next_position
        max_position = board.lists.movable.maximum(:position)
        max_position.nil? ? 0 : max_position.succ
      end

      def create_list(label, position)
        board.lists.create(label: label, list_type: :label, position: position)
      end
    end
  end
end

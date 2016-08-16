module Boards
  module Lists
    class CreateService < Boards::BaseService
      def execute
        List.transaction do
          create_list_at(next_position)
        end
      end

      private

      def next_position
        max_position = board.lists.label.maximum(:position)
        max_position.nil? ? 0 : max_position.succ
      end

      def create_list_at(position)
        board.lists.create(params.merge(list_type: :label, position: position))
      end
    end
  end
end

module Boards
  module Lists
    class CreateService < Boards::BaseService
      def execute
        List.transaction do
          position = find_next_position
          increment_higher_lists(position)
          create_list_at(position)
        end
      end

      private

      def find_next_position
        max_position = board.lists.label.maximum(:position)
        max_position.nil? ? 0 : max_position.succ
      end

      def create_list_at(position)
        board.lists.create(params.merge(list_type: :label, position: position))
      end

      def increment_higher_lists(position)
        board.lists.label.where('position >= ?', position)
                         .update_all('position = position + 1')
      end
    end
  end
end

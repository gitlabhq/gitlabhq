module Boards
  module Lists
    class DestroyService < Boards::BaseService
      def execute(list)
        return false unless list.destroyable?

        @board = list.board

        list.with_lock do
          decrement_higher_lists(list)
          remove_list(list)
        end
      end

      private

      attr_reader :board

      def decrement_higher_lists(list)
        board.lists.movable.where('position > ?',  list.position)
                   .update_all('position = position - 1')
      end

      def remove_list(list)
        list.destroy
      end
    end
  end
end

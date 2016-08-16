module Boards
  module Lists
    class DestroyService < Boards::BaseService
      def execute(list)
        return false unless list.destroyable?

        list.with_lock do
          decrement_higher_lists(list)
          remove_list(list)
        end
      end

      private

      def decrement_higher_lists(list)
        board.lists.label.where('position > ?',  list.position)
                   .update_all('position = position - 1')
      end

      def remove_list(list)
        list.destroy
      end
    end
  end
end

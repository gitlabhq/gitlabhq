module Boards
  module Lists
    class DestroyService
      def initialize(project, params = {})
        @board  = project.board
        @params = params.dup
      end

      def execute
        return false unless list.label?

        list.with_lock do
          decrement_higher_lists
          remove_list
        end
      end

      private

      attr_reader :board, :params

      def list
        @list ||= board.lists.find(params[:id])
      end

      def decrement_higher_lists
        board.lists.label.where('position > ?',  list.position)
                   .update_all('position = position - 1')
      end

      def remove_list
        list.destroy
      end
    end
  end
end

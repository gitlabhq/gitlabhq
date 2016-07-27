module Boards
  module Lists
    class MoveService
      def initialize(project, params = {})
        @board  = project.board
        @params = params.dup
      end

      def execute
        return false if new_position.blank?
        return false if new_position == old_position

        list.with_lock do
          reorder_intermediate_lists
          update_list_position
        end
      end

      private

      attr_reader :board, :params

      def list
        @list ||= board.lists.find(params[:list_id])
      end

      def old_position
        @old_position ||= list.position
      end

      def new_position
        @new_position ||= params[:position]
      end

      def reorder_intermediate_lists
        if old_position < new_position
          board.lists.where('position > ?',  old_position)
                     .where('position <= ?', new_position)
                     .update_all('position = position - 1')
        else
          board.lists.where('position >= ?', new_position)
                     .where('position < ?',  old_position)
                     .update_all('position = position + 1')
        end
      end

      def update_list_position
        list.update_attribute(:position, new_position)
      end
    end
  end
end

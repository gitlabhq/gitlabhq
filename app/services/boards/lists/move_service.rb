module Boards
  module Lists
    class MoveService
      def initialize(project, params = {})
        @board  = project.board
        @params = params.dup
      end

      def execute
        return false unless list.label?
        return false if new_position.blank?
        return false if new_position == old_position
        return false if new_position == first_position
        return false if new_position == last_position

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

      def first_position
        board.lists.first.try(:position)
      end

      def last_position
        board.lists.last.try(:position)
      end

      def old_position
        @old_position ||= list.position
      end

      def new_position
        @new_position ||= params[:position]
      end

      def reorder_intermediate_lists
        if old_position < new_position
          decrement_intermediate_lists
        else
          increment_intermediate_lists
        end
      end

      def decrement_intermediate_lists
        board.lists.where('position > ?',  old_position)
             .where('position <= ?', new_position)
             .update_all('position = position - 1')
      end

      def increment_intermediate_lists
        board.lists.where('position >= ?', new_position)
                   .where('position < ?',  old_position)
                   .update_all('position = position + 1')
      end

      def update_list_position
        list.update_attribute(:position, new_position)
      end
    end
  end
end

# frozen_string_literal: true

module Boards
  module Lists
    class MoveService < Boards::BaseService
      def execute(list)
        @board = list.board
        @old_position = list.position
        @new_position = params[:position]

        return false unless list.movable?
        return false unless valid_move?

        list.with_lock do
          reorder_intermediate_lists
          update_list_position(list)
        end
      end

      private

      attr_reader :board, :old_position, :new_position

      def valid_move?
        new_position.present? && new_position != old_position && new_position.between?(0, max_position)
      end

      def max_position
        board.lists.movable.maximum(:position)
      end

      def reorder_intermediate_lists
        if old_position < new_position
          decrement_intermediate_lists
        else
          increment_intermediate_lists
        end
      end

      # rubocop: disable CodeReuse/ActiveRecord
      def decrement_intermediate_lists
        board.lists.movable.where('position > ?',  old_position)
                           .where('position <= ?', new_position)
                           .update_all('position = position - 1')
      end
      # rubocop: enable CodeReuse/ActiveRecord

      # rubocop: disable CodeReuse/ActiveRecord
      def increment_intermediate_lists
        board.lists.movable.where('position >= ?', new_position)
                           .where('position < ?',  old_position)
                           .update_all('position = position + 1')
      end
      # rubocop: enable CodeReuse/ActiveRecord

      def update_list_position(list)
        list.update_attribute(:position, new_position)
      end
    end
  end
end

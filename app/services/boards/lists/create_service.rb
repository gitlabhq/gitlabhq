module Boards
  module Lists
    class CreateService < BaseService
      def execute(board)
        List.transaction do
          label    = find_label_for(board)
          position = next_position(board)

          create_list(board, label, position)
        end
      end

      private

      def find_label_for(board)
        if board.is_group_board?
          parent.labels.find(params[:label_id])
        else
          available_labels_for(board).find(params[:label_id])
        end
      end

      def available_labels_for(board)
        label_params =
          board.is_group_board? ? { group_id: parent.id } : { project_id: parent.id }

        LabelsFinder.new(current_user, label_params).execute
      end

      def next_position(board)
        max_position = board.lists.movable.maximum(:position)
        max_position.nil? ? 0 : max_position.succ
      end

      def create_list(board, label, position)
        board.lists.create(label: label, list_type: :label, position: position)
      end
    end
  end
end

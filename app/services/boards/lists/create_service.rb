module Boards
  module Lists
    class CreateService < Boards::BaseService
      def execute(board)
        List.transaction do
          label    = available_labels_for(board).find(params[:label_id])
          position = next_position(board)
          create_list(board, label, position)
        end
      end

      private

      def available_labels_for(board)
        options = { include_ancestor_groups: true }

        if board.group_board?
          options.merge!(group_id: parent.id, only_group_labels: true)
        else
          options[:project_id] = parent.id
        end

        LabelsFinder.new(current_user, options).execute
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

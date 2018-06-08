module Boards
  module Lists
    class CreateService < Boards::BaseService
      prepend EE::Boards::Lists::CreateService

      include Gitlab::Utils::StrongMemoize

      def execute(board)
        List.transaction do
          target = target(board)
          position = next_position(board)
          create_list(board, type, target, position)
        end
      end

      private

      def type
        :label
      end

      def target(board)
        strong_memoize(:target) do
          available_labels_for(board).find(params[:label_id])
        end
      end

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

      def create_list(board, type, target, position)
        board.lists.create(type => target, list_type: type, position: position)
      end
    end
  end
end

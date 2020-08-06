# frozen_string_literal: true

module Boards
  module Lists
    class CreateService < Boards::BaseService
      include Gitlab::Utils::StrongMemoize

      def execute(board)
        List.transaction do
          case type
          when :backlog
            create_backlog(board)
          else
            target = target(board)
            position = next_position(board)

            create_list(board, type, target, position)
          end
        end
      end

      private

      def type
        # We don't ever expect to have more than one list
        # type param at once.
        if params.key?('backlog')
          :backlog
        else
          :label
        end
      end

      def target(board)
        strong_memoize(:target) do
          available_labels.find(params[:label_id])
        end
      end

      def available_labels
        ::Labels::AvailableLabelsService.new(current_user, parent, {})
          .available_labels
      end

      def next_position(board)
        max_position = board.lists.movable.maximum(:position)
        max_position.nil? ? 0 : max_position.succ
      end

      def create_list(board, type, target, position)
        board.lists.create(create_list_attributes(type, target, position))
      end

      def create_list_attributes(type, target, position)
        { type => target, list_type: type, position: position }
      end

      def create_backlog(board)
        return board.lists.backlog.first if board.lists.backlog.exists?

        board.lists.create(list_type: :backlog, position: nil)
      end
    end
  end
end

Boards::Lists::CreateService.prepend_if_ee('EE::Boards::Lists::CreateService')

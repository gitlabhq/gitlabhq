# frozen_string_literal: true

module Boards
  module Lists
    # This class is used by issue and epic board lists
    # for creating new list
    class BaseCreateService < Boards::BaseService
      include Gitlab::Utils::StrongMemoize

      def execute(board)
        list = case type
               when :backlog
                 create_backlog(board)
               else
                 target = target(board)
                 position = params[:position] || next_position(board)

                 return ServiceResponse.error(message: _('%{board_target} not found') % { board_target: type.to_s.capitalize }) if target.blank?

                 reorder_subsequent_lists!(board, position)
                 create_list(board, type, target, position)
               end

        return ServiceResponse.error(message: list.errors.full_messages) unless list.persisted?

        ServiceResponse.success(payload: { list: list })
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
          available_labels.find_by(id: params[:label_id]) # rubocop: disable CodeReuse/ActiveRecord
        end
      end

      def available_labels
        ::Labels::AvailableLabelsService.new(current_user, parent, {})
          .available_labels
      end

      # Shift each list that is after the new list's position so that they
      # are in the correct order.
      def reorder_subsequent_lists!(board, insert_position)
        lists = board.lists.movable.ordered.positioned_at_or_after(insert_position)

        return if lists.empty?

        mapping = lists.map.with_index do |list, i|
          [list, { position: insert_position + i + 1 }]
        end.to_h

        ::Gitlab::Database::BulkUpdate.execute(%i[position], mapping)
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

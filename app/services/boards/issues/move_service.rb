module Boards
  module Issues
    class MoveService < Boards::BaseService
      def execute(issue)
        return false unless can?(current_user, :update_issue, issue)
        return false unless valid_move?

        update_service.execute(issue)
      end

      private

      def valid_move?
        moving_from_list.present? && moving_to_list.present? &&
          moving_from_list != moving_to_list
      end

      def moving_from_list
        @moving_from_list ||= board.lists.find_by(id: params[:from_list_id])
      end

      def moving_to_list
        @moving_to_list ||= board.lists.find_by(id: params[:to_list_id])
      end

      def update_service
        ::Issues::UpdateService.new(project, current_user, issue_params)
      end

      def issue_params
        {
          add_label_ids: add_label_ids,
          remove_label_ids: remove_label_ids,
          state_event: issue_state
        }
      end

      def issue_state
        return 'reopen' if moving_from_list.done?
        return 'close'  if moving_to_list.done?
      end

      def add_label_ids
        [moving_to_list.label_id].compact
      end

      def remove_label_ids
        label_ids =
          if moving_to_list.movable?
            moving_from_list.label_id
          else
            board.lists.movable.pluck(:label_id)
          end

        Array(label_ids).compact
      end
    end
  end
end

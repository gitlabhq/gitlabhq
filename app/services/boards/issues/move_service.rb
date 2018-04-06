module Boards
  module Issues
    class MoveService < Boards::BaseService
      def execute(issue)
        return false unless can?(current_user, :update_issue, issue)
        return false if issue_params.empty?

        update(issue)
      end

      private

      def board
        @board ||= parent.boards.find(params[:board_id])
      end

      def move_between_lists?
        moving_from_list.present? && moving_to_list.present? &&
          moving_from_list != moving_to_list
      end

      def moving_from_list
        @moving_from_list ||= board.lists.find_by(id: params[:from_list_id])
      end

      def moving_to_list
        @moving_to_list ||= board.lists.find_by(id: params[:to_list_id])
      end

      def update(issue)
        ::Issues::UpdateService.new(issue.project, current_user, issue_params).execute(issue)
      end

      def issue_params
        attrs = {}

        if move_between_lists?
          attrs.merge!(
            add_label_ids: add_label_ids,
            remove_label_ids: remove_label_ids,
            state_event: issue_state
          )
        end

        if move_between_ids
          attrs[:move_between_ids] = move_between_ids
          attrs[:board_group_id] =  board.group&.id
        end

        attrs
      end

      def issue_state
        return 'reopen' if moving_from_list.closed?
        return 'close'  if moving_to_list.closed?
      end

      def add_label_ids
        [moving_to_list.label_id].compact
      end

      def remove_label_ids
        label_ids =
          if moving_to_list.movable?
            moving_from_list.label_id
          elsif board.group_board?
            ::Label.on_group_boards(parent.id).pluck(:label_id)
          else
            ::Label.on_project_boards(parent.id).pluck(:label_id)
          end

        Array(label_ids).compact
      end

      def move_between_ids
        return unless params[:move_after_id] || params[:move_before_id]

        [params[:move_after_id], params[:move_before_id]]
      end
    end
  end
end

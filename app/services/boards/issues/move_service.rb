module Boards
  module Issues
    class MoveService < Boards::BaseService
      def execute
        return false unless issue.present?
        return false unless valid_move?

        update_service.execute(issue)
        reopen_service.execute(issue) if moving_from.done?
        close_service.execute(issue)  if moving_to.done?

        true
      end

      private

      def valid_move?
        moving_from.present? && moving_to.present?
      end

      def issue
        @issue ||= project.issues.visible_to_user(user).find_by!(iid: params[:id])
      end

      def moving_from
        @moving_from ||= board.lists.find_by(id: params[:from])
      end

      def moving_to
        @moving_to ||= board.lists.find_by(id: params[:to])
      end

      def close_service
        ::Issues::CloseService.new(project, user)
      end

      def reopen_service
        ::Issues::ReopenService.new(project, user)
      end

      def update_service
        ::Issues::UpdateService.new(project, user, issue_params)
      end

      def issue_params
        {
          add_label_ids: add_label_ids,
          remove_label_ids: remove_label_ids
        }
      end

      def add_label_ids
        [moving_to.label_id].compact
      end

      def remove_label_ids
        label_ids =
          if moving_to.label?
            moving_from.label_id
          else
            board.lists.label.pluck(:label_id)
          end

        Array(label_ids).compact
      end
    end
  end
end

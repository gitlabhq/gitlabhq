# frozen_string_literal: true

module Boards
  module Issues
    class MoveService < Boards::BaseService
      def execute(issue)
        issue_modification_params = issue_params(issue)
        return false if issue_modification_params.empty?

        move_single_issue(issue, issue_modification_params)
      end

      def execute_multiple(issues)
        return false if issues.empty?

        last_inserted_issue_id = nil
        issues.map do |issue|
          issue_modification_params = issue_params(issue)
          next if issue_modification_params.empty?

          if last_inserted_issue_id
            issue_modification_params[:move_between_ids] = move_between_ids({ move_after_id: nil, move_before_id: last_inserted_issue_id })
          end

          last_inserted_issue_id = issue.id
          move_single_issue(issue, issue_modification_params)
        end.all?
      end

      private

      def move_single_issue(issue, issue_modification_params)
        return false unless can?(current_user, :update_issue, issue)

        update(issue, issue_modification_params)
      end

      def board
        @board ||= parent.boards.find(params[:board_id])
      end

      def move_between_lists?
        moving_from_list.present? && moving_to_list.present? &&
          moving_from_list != moving_to_list
      end

      # rubocop: disable CodeReuse/ActiveRecord
      def moving_from_list
        @moving_from_list ||= board.lists.find_by(id: params[:from_list_id])
      end
      # rubocop: enable CodeReuse/ActiveRecord

      # rubocop: disable CodeReuse/ActiveRecord
      def moving_to_list
        @moving_to_list ||= board.lists.find_by(id: params[:to_list_id])
      end
      # rubocop: enable CodeReuse/ActiveRecord

      def update(issue, issue_modification_params)
        ::Issues::UpdateService.new(issue.project, current_user, issue_modification_params).execute(issue)
      end

      def issue_params(issue)
        attrs = {}

        if move_between_lists?
          attrs.merge!(
            add_label_ids: add_label_ids,
            remove_label_ids: remove_label_ids,
            state_event: issue_state
          )
        end

        move_between_ids = move_between_ids(params)
        if move_between_ids
          attrs[:move_between_ids] = move_between_ids
          attrs[:board_group_id] = board.group&.id
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

      # rubocop: disable CodeReuse/ActiveRecord
      def remove_label_ids
        label_ids =
          if moving_to_list.movable?
            moving_from_list.label_id
          else
            ::Label.on_board(board.id).pluck(:label_id)
          end

        Array(label_ids).compact
      end
      # rubocop: enable CodeReuse/ActiveRecord

      def move_between_ids(move_params)
        ids = [move_params[:move_after_id], move_params[:move_before_id]]
                .map(&:to_i)
                .map { |m| m.positive? ? m : nil }

        ids.any? ? ids : nil
      end
    end
  end
end

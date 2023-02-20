# frozen_string_literal: true

module Boards
  module Issues
    class MoveService < Boards::BaseItemMoveService
      def execute_multiple(issues)
        return execute_multiple_empty_result if issues.empty?

        handled_issues = []
        last_inserted_issue_id = nil
        count = issues.each.inject(0) do |moved_count, issue|
          issue_modification_params = issuable_params(issue)
          next moved_count if issue_modification_params.empty?

          if last_inserted_issue_id
            issue_modification_params[:move_between_ids] = move_below(last_inserted_issue_id)
          end

          last_inserted_issue_id = issue.id
          handled_issue = move_single_issuable(issue, issue_modification_params)
          handled_issues << present_issue_entity(handled_issue) if handled_issue
          handled_issue && handled_issue.valid? ? moved_count + 1 : moved_count
        end

        {
          count: count,
          success: count == issues.size,
          issues: handled_issues
        }
      end

      private

      def present_issue_entity(issue)
        ::API::Entities::Issue.represent(issue)
      end

      def execute_multiple_empty_result
        @execute_multiple_empty_result ||= {
          count: 0,
          success: false,
          issues: []
        }
      end

      def move_below(id)
        move_between_ids({ move_after_id: nil, move_before_id: id })
      end

      def board
        @board ||= parent.boards.find(params[:board_id])
      end

      def update(issue, issue_modification_params)
        ::Issues::UpdateService.new(container: issue.project, current_user: current_user, params: issue_modification_params).execute(issue)
      end

      def moving_to_list_items_relation
        Boards::Issues::ListService.new(board.resource_parent, current_user, board_id: board.id, id: moving_to_list.id).execute
      end
    end
  end
end

Boards::Issues::MoveService.prepend_mod_with('Boards::Issues::MoveService')

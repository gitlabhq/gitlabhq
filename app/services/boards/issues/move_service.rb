# frozen_string_literal: true

module Boards
  module Issues
    class MoveService < Boards::BaseItemMoveService
      extend ::Gitlab::Utils::Override

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
        ::Issues::UpdateService.new(issue.project, current_user, issue_modification_params).execute(issue)
      end

      override :issuable_params
      def issuable_params(issuable)
        attrs = super

        move_between_ids = move_between_ids(params)
        if move_between_ids
          attrs[:move_between_ids] = move_between_ids
          attrs[:board_group_id] = board.group&.id
        end

        attrs
      end

      def move_between_ids(move_params)
        ids = [move_params[:move_after_id], move_params[:move_before_id]]
                .map(&:to_i)
                .map { |m| m > 0 ? m : nil }

        ids.any? ? ids : nil
      end
    end
  end
end

Boards::Issues::MoveService.prepend_if_ee('EE::Boards::Issues::MoveService')

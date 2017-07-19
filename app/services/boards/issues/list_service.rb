module Boards
  module Issues
    class ListService < BaseService
      def execute
        issues = IssuesFinder.new(current_user, filter_params).execute
        issues = without_board_labels(issues) unless movable_list? || closed_list?
        issues = with_list_label(issues) if movable_list?
        issues.order_by_position_and_priority
      end

      private

      def board
        @board ||= project.boards.find(params[:board_id])
      end

      def list
        return @list if defined?(@list)

        @list = board.lists.find(params[:id]) if params.key?(:id)
      end

      def movable_list?
        return @movable_list if defined?(@movable_list)

        @movable_list = list.present? && list.movable?
      end

      def closed_list?
        return @closed_list if defined?(@closed_list)

        @closed_list = list.present? && list.closed?
      end

      def filter_params
        set_project
        set_state

        params
      end

      def set_project
        params[:project_id] = project.id
      end

      def set_state
        params[:state] = list && list.closed? ? 'closed' : 'opened'
      end

      def board_label_ids
        @board_label_ids ||= board.lists.movable.pluck(:label_id)
      end

      def without_board_labels(issues)
        return issues unless board_label_ids.any?

        label_links = LabelLink.where("label_links.target_type = 'Issue' AND label_links.target_id = issues.id")
                               .where(label_id: board_label_ids)

        if board.milestone.present?
          label_links = label_links.where("issues.milestone_id = ?", board.milestone_id)
        end

        issues.where.not(label_links.limit(1).arel.exists)
      end

      def with_list_label(issues)
        issues.where(
          LabelLink.where("label_links.target_type = 'Issue' AND label_links.target_id = issues.id")
                   .where("label_links.label_id = ?", list.label_id).limit(1).arel.exists
        )
      end
    end
  end
end

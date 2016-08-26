module Boards
  module Issues
    class ListService < Boards::BaseService
      def execute
        issues = IssuesFinder.new(current_user, filter_params).execute
        issues = without_board_labels(issues) unless list.movable?
        issues = with_list_label(issues) if list.movable?
        issues
      end

      private

      def list
        @list ||= board.lists.find(params[:id])
      end

      def filter_params
        set_default_scope
        set_default_sort
        set_project
        set_state

        params
      end

      def set_default_scope
        params[:scope] = 'all'
      end

      def set_default_sort
        params[:sort] = 'priority'
      end

      def set_project
        params[:project_id] = project.id
      end

      def set_state
        params[:state] =
          case list.list_type.to_sym
          when :backlog then 'opened'
          when :done then 'closed'
          else 'all'
          end
      end

      def board_label_ids
        @board_label_ids ||= board.lists.movable.pluck(:label_id)
      end

      def without_board_labels(issues)
        return issues unless board_label_ids.any?

        issues.where.not(
          LabelLink.where("label_links.target_type = 'Issue' AND label_links.target_id = issues.id")
                   .where(label_id: board_label_ids).limit(1).arel.exists
        )
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

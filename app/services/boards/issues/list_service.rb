module Boards
  module Issues
    class ListService < Boards::BaseService
      def execute
        issues = IssuesFinder.new(user, filter_params).execute
        issues = without_board_labels(issues) if list.backlog?
        issues
      end

      private

      def list
        @list ||= board.lists.find(params[:id])
      end

      def filter_params
        set_default_scope
        set_default_sort
        set_list_label
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

      def set_list_label
        return unless list.label?

        params[:label_name] ||= []
        params[:label_name] << list.label_name
      end

      def set_project
        params[:project_id] = project.id
      end

      def set_state
        params[:state] = list.done? ? 'closed' : 'opened'
      end

      def board_label_ids
        @board_label_ids ||= board.lists.label.pluck(:label_id)
      end

      def without_board_labels(issues)
        return issues unless board_label_ids.any?

        issues.where.not(
          LabelLink.where("label_links.target_type = 'Issue' AND label_links.target_id = issues.id")
                   .where(label_id: board_label_ids).limit(1).arel.exists
        )
      end
    end
  end
end

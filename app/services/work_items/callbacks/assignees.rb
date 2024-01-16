# frozen_string_literal: true

module WorkItems
  module Callbacks
    class Assignees < Base
      def before_update
        params[:assignee_ids] = [] if excluded_in_new_type?

        return unless params.present? && params.has_key?(:assignee_ids)
        return unless has_permission?(:set_work_item_metadata)

        assignee_ids = filter_assignees_count(params[:assignee_ids])
        assignee_ids = filter_assignee_permissions(assignee_ids)

        return if assignee_ids.sort == work_item.assignee_ids.sort

        work_item.assignee_ids = assignee_ids
        work_item.touch
      end

      private

      def filter_assignees_count(assignee_ids)
        return assignee_ids if work_item.allows_multiple_assignees?

        assignee_ids.first(1)
      end

      def filter_assignee_permissions(assignee_ids)
        assignees = User.id_in(assignee_ids)

        assignees.select { |assignee| assignee.can?(:read_work_item, work_item) }.map(&:id)
      end
    end
  end
end

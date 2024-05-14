# frozen_string_literal: true

module WorkItems
  module Callbacks
    class Assignees < Base
      def before_create
        set_assignee_ids
      end

      def before_update
        set_assignee_ids
      end

      private

      def set_assignee_ids
        params[:assignee_ids] = [] if excluded_in_new_type?
        return unless params.has_key?(:assignee_ids) && has_permission?(:set_work_item_metadata)

        new_assignee_ids = filter_assignee_ids(params[:assignee_ids])
        return if new_assignee_ids.sort == work_item.assignee_ids.sort

        work_item.assignee_ids = new_assignee_ids
      end

      def filter_assignee_ids(assignee_ids)
        assignee_ids = assignee_ids.first(1) unless work_item.allows_multiple_assignees?

        assignees = User.id_in(assignee_ids)
        assignees.select { |assignee| assignee.can?(:read_work_item, work_item) }.map(&:id)
      end
    end
  end
end

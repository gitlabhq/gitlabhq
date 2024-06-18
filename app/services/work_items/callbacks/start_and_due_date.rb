# frozen_string_literal: true

module WorkItems
  module Callbacks
    class StartAndDueDate < Base
      def before_update
        return work_item.assign_attributes({ start_date: nil, due_date: nil }) if excluded_in_new_type?

        return unless update_start_and_due_date?

        work_item.assign_attributes(params.slice(:start_date, :due_date))
      end

      private

      def update_start_and_due_date?
        params.present? && has_permission?(:set_work_item_metadata)
      end
    end
  end
end

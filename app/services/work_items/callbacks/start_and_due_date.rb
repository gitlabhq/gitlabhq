# frozen_string_literal: true

module WorkItems
  module Callbacks
    class StartAndDueDate < Base
      def before_update
        return work_item.assign_attributes({ start_date: nil, due_date: nil }) if excluded_in_new_type?

        return if params.blank?
        return unless has_permission?(:set_work_item_metadata)

        work_item.assign_attributes(params.slice(:start_date, :due_date))
      end
    end
  end
end

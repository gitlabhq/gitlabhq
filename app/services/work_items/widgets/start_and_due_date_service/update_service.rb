# frozen_string_literal: true

module WorkItems
  module Widgets
    module StartAndDueDateService
      class UpdateService < WorkItems::Widgets::BaseService
        def before_update_callback(params: {})
          return if params.blank?

          widget.work_item.assign_attributes(params.slice(:start_date, :due_date))
        end
      end
    end
  end
end

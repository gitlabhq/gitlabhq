# frozen_string_literal: true

module WorkItems
  module Callbacks
    class TimeTracking < Base
      def after_initialize
        if excluded_in_new_type?
          params.delete(:time_estimate)
          params.delete(:spend_time)
        end

        return unless has_permission?(:admin_work_item)
        return if !params.present? || (!params.key?(:time_estimate) && !params.key?(:spend_time))

        work_item.time_estimate = params[:time_estimate] if params[:time_estimate].present?
        work_item.spend_time = params[:spend_time] if params[:spend_time].present?
      end
    end
  end
end

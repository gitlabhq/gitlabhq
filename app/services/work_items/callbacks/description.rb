# frozen_string_literal: true

module WorkItems
  module Callbacks
    class Description < Base
      def after_initialize
        params[:description] = nil if excluded_in_new_type?

        return unless params.present? && params.key?(:description)
        return unless has_permission?(:update_work_item)

        work_item.description = params[:description]
        work_item.assign_attributes(last_edited_at: Time.current, last_edited_by: current_user)
      end
    end
  end
end

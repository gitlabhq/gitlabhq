# frozen_string_literal: true

module WorkItems
  module Widgets
    module DescriptionService
      class UpdateService < WorkItems::Widgets::BaseService
        def before_update_callback(params: {})
          return unless params.present? && params.key?(:description)
          return unless has_permission?(:update_work_item)

          work_item.description = params[:description]
          work_item.assign_attributes(last_edited_at: Time.current, last_edited_by: current_user)
        end
      end
    end
  end
end

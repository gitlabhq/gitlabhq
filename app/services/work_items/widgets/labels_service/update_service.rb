# frozen_string_literal: true

module WorkItems
  module Widgets
    module LabelsService
      class UpdateService < WorkItems::Widgets::BaseService
        def prepare_update_params(params: {})
          if new_type_excludes_widget?
            params[:remove_label_ids] = @work_item.labels.map(&:id)
            params[:add_label_ids] = []
          end

          return if params.blank?

          service_params.merge!(params.slice(:add_label_ids, :remove_label_ids))
        end
      end
    end
  end
end

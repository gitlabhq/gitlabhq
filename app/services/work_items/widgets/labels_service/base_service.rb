# frozen_string_literal: true

module WorkItems
  module Widgets
    module LabelsService
      class BaseService < WorkItems::Widgets::BaseService
        private

        def prepare_params(params: {}, permitted_params: [])
          clear_label_params(params) if new_type_excludes_widget?

          return if params.blank?
          return unless has_permission?(:set_work_item_metadata)

          service_params.merge!(params.slice(*permitted_params))
        end

        def clear_label_params(params)
          params[:remove_label_ids] = @work_item.labels.map(&:id)
          params[:add_label_ids] = []
        end
      end
    end
  end
end

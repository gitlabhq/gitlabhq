# frozen_string_literal: true

module WorkItems
  module Widgets
    module LabelsService
      class UpdateService < BaseService
        def prepare_update_params(params: {})
          clear_label_params(params) if new_type_excludes_widget?

          prepare_params(params: params, permitted_params: %i[add_label_ids remove_label_ids])
        end

        private

        def clear_label_params(params)
          params[:remove_label_ids] = @work_item.labels.map(&:id)
          params[:add_label_ids] = []
        end
      end
    end
  end
end

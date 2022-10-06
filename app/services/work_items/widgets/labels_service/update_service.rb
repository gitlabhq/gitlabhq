# frozen_string_literal: true

module WorkItems
  module Widgets
    module LabelsService
      class UpdateService < WorkItems::Widgets::BaseService
        def prepare_update_params(params: {})
          return if params.blank?

          service_params.merge!(params.slice(:add_label_ids, :remove_label_ids))
        end
      end
    end
  end
end

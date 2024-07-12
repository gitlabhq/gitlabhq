# frozen_string_literal: true

module WorkItems
  module Widgets
    module LabelsService
      class BaseService < WorkItems::Widgets::BaseService
        private

        def prepare_params(params: {}, permitted_params: [])
          return if params.blank?
          return unless has_permission?(:set_work_item_metadata)

          service_params.merge!(params.slice(*permitted_params))
        end
      end
    end
  end
end

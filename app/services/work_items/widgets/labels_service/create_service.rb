# frozen_string_literal: true

module WorkItems
  module Widgets
    module LabelsService
      class CreateService < BaseService
        def prepare_create_params(params: {})
          prepare_params(params: params, permitted_params: %i[add_label_ids remove_label_ids label_ids])
        end

        def clear_label_params(params)
          params[:add_label_ids] = []
          params[:label_ids] = []
        end
      end
    end
  end
end

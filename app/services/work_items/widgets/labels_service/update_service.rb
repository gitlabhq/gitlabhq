# frozen_string_literal: true

module WorkItems
  module Widgets
    module LabelsService
      class UpdateService < BaseService
        def prepare_update_params(params: {})
          prepare_params(params: params, permitted_params: %i[add_label_ids remove_label_ids])
        end
      end
    end
  end
end

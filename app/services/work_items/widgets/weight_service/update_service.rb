# frozen_string_literal: true

module WorkItems
  module Widgets
    module WeightService
      class UpdateService < WorkItems::Widgets::BaseService
        def update(params: {})
          return unless params.present? && params[:weight]

          widget.work_item.weight = params[:weight]
        end
      end
    end
  end
end

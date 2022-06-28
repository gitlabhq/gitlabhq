# frozen_string_literal: true

module WorkItems
  module Widgets
    module DescriptionService
      class UpdateService < WorkItems::Widgets::BaseService
        def update(params: {})
          return unless params.present? && params[:description]

          widget.work_item.description = params[:description]
        end
      end
    end
  end
end

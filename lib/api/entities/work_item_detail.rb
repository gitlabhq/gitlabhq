# frozen_string_literal: true

module API
  module Entities
    class WorkItemDetail < Grape::Entity
      include WorkItems::BasicFields

      expose :features,
        using: ::API::Entities::WorkItems::Features::DetailEntity,
        documentation: { type: 'Entities::WorkItems::Features::DetailEntity' },
        expose_nil: false,
        if: ->(_work_item, options) { options[:requested_features].present? } do |work_item|
        work_item
      end
    end
  end
end

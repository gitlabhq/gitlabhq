# frozen_string_literal: true

module API
  module Entities
    class WorkItemBasic < Grape::Entity
      include WorkItems::BasicFields

      expose :features,
        using: ::API::Entities::WorkItems::Features::Entity,
        documentation: { type: 'Entities::WorkItems::Features::Entity' },
        expose_nil: false,
        if: ->(_work_item, options) { options[:requested_features].present? } do |work_item|
        work_item
      end
    end
  end
end

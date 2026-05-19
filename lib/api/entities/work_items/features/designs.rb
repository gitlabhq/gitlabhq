# frozen_string_literal: true

module API
  module Entities
    module WorkItems
      module Features
        class Designs < Grape::Entity
          class DesignCollection < Grape::Entity
            expose :copy_state,
              documentation: { type: 'String', example: 'ready', values: %w[ready in_progress error] },
              expose_nil: true
          end

          expose :design_collection,
            using: ::API::Entities::WorkItems::Features::Designs::DesignCollection,
            documentation: { type: 'Entities::WorkItems::Features::Designs::DesignCollection' },
            expose_nil: true
        end
      end
    end
  end
end

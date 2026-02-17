# frozen_string_literal: true

module API
  module Entities
    module WorkItems
      module Features
        class Labels < Grape::Entity
          expose :allows_scoped_labels?, as: :allows_scoped_labels,
            documentation: { type: 'Boolean', example: true }
          expose :labels, using: ::API::Entities::WorkItems::Label,
            documentation: { type: 'Entities::WorkItems::Label', is_array: true }
        end
      end
    end
  end
end

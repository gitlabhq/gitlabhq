# frozen_string_literal: true

module API
  module Entities
    module WorkItems
      module Features
        class Labels < Grape::Entity
          expose :allows_scoped_labels, as: :allows_scoped_labels,
            documentation: { type: 'Boolean', example: true }
          expose :labels, using: ::API::Entities::WorkItems::Label,
            documentation: { type: 'Entities::WorkItems::Label', is_array: true }

          private

          def allows_scoped_labels
            resource_parent = options[:resource_parent]
            return object.allows_scoped_labels? unless resource_parent

            resource_parent.licensed_feature_available?(:scoped_labels)
          end
        end
      end
    end
  end
end

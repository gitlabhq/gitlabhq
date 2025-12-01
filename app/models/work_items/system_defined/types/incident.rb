# frozen_string_literal: true

module WorkItems
  module SystemDefined
    module Types
      module Incident
        def self.configuration
          {
            id: 2,
            name: 'Incident',
            base_type: 'incident',
            icon_name: 'work-item-incident'
          }
        end
      end
    end
  end
end

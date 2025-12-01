# frozen_string_literal: true

module WorkItems
  module SystemDefined
    module Types
      module Ticket
        def self.configuration
          {
            id: 9,
            name: 'Ticket',
            base_type: 'ticket',
            icon_name: "work-item-ticket"
          }
        end
      end
    end
  end
end

# frozen_string_literal: true

module WorkItems
  module SystemDefined
    module Types
      module Issue
        def self.configuration
          {
            id: 1,
            name: 'Issue',
            base_type: 'issue',
            icon_name: "work-item-issue"
          }
        end
      end
    end
  end
end

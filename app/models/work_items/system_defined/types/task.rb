# frozen_string_literal: true

module WorkItems
  module SystemDefined
    module Types
      module Task
        def self.configuration
          {
            id: 5,
            name: 'Task',
            base_type: 'task',
            icon_name: "work-item-task"
          }
        end
      end
    end
  end
end

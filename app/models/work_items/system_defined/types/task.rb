# frozen_string_literal: true

module WorkItems
  module SystemDefined
    module Types
      module Task
        class << self
          def widgets
            %w[
              assignees
              award_emoji
              crm_contacts
              current_user_todos
              custom_fields
              description
              development
              hierarchy
              iteration
              labels
              linked_items
              linked_resources
              milestone
              notes
              notifications
              participants
              start_and_due_date
              time_tracking
              weight
              status
            ]
          end

          def widget_options
            { weight: { editable: true, rollup: false } }
          end

          def configuration
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
end

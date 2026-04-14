# frozen_string_literal: true

module WorkItems
  module TypesFramework
    module SystemDefined
      module Definitions
        module Task
          class << self
            def widgets
              %w[
                ai_session
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
              {}
            end

            def configuration
              {
                id: 5,
                name: 'Task',
                base_type: 'task',
                icon_name: "work-item-task"
              }
            end

            def filterable_board_view?(resource_parent)
              !!resource_parent.try(:work_item_tasks_on_boards_feature_flag_enabled?)
            end
          end
        end
      end
    end
  end
end

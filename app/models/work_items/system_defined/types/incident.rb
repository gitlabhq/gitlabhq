# frozen_string_literal: true

module WorkItems
  module SystemDefined
    module Types
      module Incident
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
              email_participants
              hierarchy
              iteration
              labels
              linked_items
              linked_resources
              milestone
              notes
              notifications
              participants
              time_tracking
            ]
          end

          def widget_options
            {}
          end

          def configuration
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
end

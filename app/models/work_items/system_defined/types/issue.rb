# frozen_string_literal: true

module WorkItems
  module SystemDefined
    module Types
      module Issue
        class << self
          def widgets
            %w[
              assignees
              award_emoji
              crm_contacts
              current_user_todos
              custom_fields
              description
              designs
              development
              email_participants
              error_tracking
              health_status
              hierarchy
              iteration
              labels
              linked_items
              milestone
              notes
              notifications
              participants
              start_and_due_date
              time_tracking
              vulnerabilities
              linked_resources
              weight
              status
            ]
          end

          def widget_options
            { weight: { editable: true, rollup: false } }
          end

          def configuration
            {
              id: 1,
              name: 'Issue',
              base_type: 'issue',
              icon_name: "work-item-issue"
            }
          end

          # This method adds a configuration for the parent of the Type, and it coresponding license.
          # The format should be { parent.base_type.to_s: license_name.to_sym}
          def licenses_for_parent
            { 'epic' => :epics }
          end
        end
      end
    end
  end
end

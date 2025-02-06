# frozen_string_literal: true

module Gitlab
  module DatabaseImporters
    module WorkItems
      module BaseTypeImporter
        WIDGET_NAMES = {
          assignees: 'Assignees',
          labels: 'Labels',
          description: 'Description',
          hierarchy: 'Hierarchy',
          start_and_due_date: 'Start and due date',
          milestone: 'Milestone',
          notes: 'Notes',
          iteration: 'Iteration',
          weight: 'Weight',
          health_status: 'Health status',
          progress: 'Progress',
          status: 'Status',
          requirement_legacy: 'Requirement legacy',
          test_reports: 'Test reports',
          notifications: 'Notifications',
          current_user_todos: 'Current user todos',
          award_emoji: 'Award emoji',
          linked_items: 'Linked items',
          color: 'Color',
          participants: 'Participants',
          time_tracking: 'Time tracking',
          designs: 'Designs',
          development: 'Development',
          crm_contacts: 'CRM contacts',
          email_participants: 'Email participants',
          custom_status: 'Custom status',
          custom_fields: 'Custom fields'
        }.freeze

        WIDGETS_FOR_TYPE = {
          issue: [
            :assignees,
            :award_emoji,
            :crm_contacts,
            :current_user_todos,
            :custom_fields,
            :description,
            :designs,
            :development,
            :email_participants,
            :health_status,
            :hierarchy,
            :iteration,
            :labels,
            :linked_items,
            :milestone,
            :notes,
            :notifications,
            :participants,
            :start_and_due_date,
            :time_tracking,
            [:weight, { editable: true, rollup: false }]
          ],
          incident: [
            :assignees,
            :award_emoji,
            :crm_contacts,
            :current_user_todos,
            :custom_fields,
            :description,
            :development,
            :email_participants,
            :hierarchy,
            :iteration,
            :labels,
            :linked_items,
            :milestone,
            :notes,
            :notifications,
            :participants,
            :time_tracking
          ],
          test_case: [
            :award_emoji,
            :current_user_todos,
            :custom_fields,
            :description,
            :linked_items,
            :notes,
            :notifications,
            :participants,
            :time_tracking
          ],
          requirement: [
            :award_emoji,
            :current_user_todos,
            :custom_fields,
            :description,
            :linked_items,
            :notes,
            :notifications,
            :participants,
            :requirement_legacy,
            :status,
            :test_reports,
            :time_tracking
          ],
          task: [
            :assignees,
            :award_emoji,
            :crm_contacts,
            :current_user_todos,
            :custom_fields,
            :description,
            :development,
            :hierarchy,
            :iteration,
            :labels,
            :linked_items,
            :milestone,
            :notes,
            :notifications,
            :participants,
            :start_and_due_date,
            :time_tracking,
            [:weight, { editable: true, rollup: false }],
            :custom_status
          ],
          objective: [
            :assignees,
            :award_emoji,
            :current_user_todos,
            :custom_fields,
            :description,
            :health_status,
            :hierarchy,
            :labels,
            :linked_items,
            :milestone,
            :notes,
            :notifications,
            :participants,
            :progress
          ],
          key_result: [
            :assignees,
            :award_emoji,
            :current_user_todos,
            :custom_fields,
            :description,
            :health_status,
            :hierarchy,
            :labels,
            :linked_items,
            :notes,
            :notifications,
            :participants,
            :start_and_due_date,
            :progress
          ],
          epic: [
            :assignees,
            :award_emoji,
            :color,
            :crm_contacts,
            :current_user_todos,
            :custom_fields,
            :description,
            :health_status,
            :hierarchy,
            :labels,
            :linked_items,
            :notes,
            :notifications,
            :participants,
            :start_and_due_date,
            :status,
            :time_tracking,
            [:weight, { editable: false, rollup: true }]
          ],
          ticket: [
            :assignees,
            :award_emoji,
            :crm_contacts,
            :current_user_todos,
            :custom_fields,
            :description,
            :designs,
            :development,
            :email_participants,
            :health_status,
            :hierarchy,
            :iteration,
            :labels,
            :linked_items,
            :milestone,
            :notes,
            :notifications,
            :participants,
            :start_and_due_date,
            :time_tracking,
            [:weight, { editable: true, rollup: false }]
          ]
        }.freeze

        def self.upsert_types
          current_time = Time.current

          base_types = ::WorkItems::Type::BASE_TYPES.map do |type, attributes|
            attributes
              .slice(:name, :icon_name, :id)
              .merge(created_at: current_time, updated_at: current_time, base_type: type, correct_id: attributes[:id])
          end

          ::WorkItems::Type.upsert_all(
            base_types,
            unique_by: :index_work_item_types_on_name_unique,
            update_only: %i[name icon_name base_type]
          )

          upsert_widgets
        end

        def self.upsert_widgets
          type_ids_by_name = ::WorkItems::Type.pluck(:name, :id).to_h # rubocop: disable CodeReuse/ActiveRecord

          widgets = WIDGETS_FOR_TYPE.flat_map do |type_sym, widget_syms|
            type_name = ::WorkItems::Type::TYPE_NAMES[type_sym]

            widget_syms.map do |widget_sym|
              widget_sym, widget_options = widget_sym if widget_sym.is_a?(Array)

              {
                work_item_type_id: type_ids_by_name[type_name],
                name: WIDGET_NAMES[widget_sym],
                widget_type: ::WorkItems::WidgetDefinition.widget_types[widget_sym],
                widget_options: widget_options
              }
            end
          end

          ::WorkItems::WidgetDefinition.upsert_all(
            widgets,
            unique_by: :index_work_item_widget_definitions_on_type_id_and_name
          )
        end
      end
    end
  end
end

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
          current_user_todos: "Current user todos",
          award_emoji: 'Award emoji'
        }.freeze

        WIDGETS_FOR_TYPE = {
          issue: [
            :assignees,
            :labels,
            :description,
            :hierarchy,
            :start_and_due_date,
            :milestone,
            :notes,
            :iteration,
            :weight,
            :health_status,
            :notifications,
            :current_user_todos,
            :award_emoji
          ],
          incident: [
            :assignees,
            :description,
            :hierarchy,
            :notes,
            :notifications,
            :current_user_todos,
            :award_emoji
          ],
          test_case: [
            :description,
            :notes,
            :notifications,
            :current_user_todos,
            :award_emoji
          ],
          requirement: [
            :description,
            :notes,
            :status,
            :requirement_legacy,
            :test_reports,
            :notifications,
            :current_user_todos,
            :award_emoji
          ],
          task: [
            :assignees,
            :labels,
            :description,
            :hierarchy,
            :start_and_due_date,
            :milestone,
            :notes,
            :iteration,
            :weight,
            :notifications,
            :current_user_todos,
            :award_emoji
          ],
          objective: [
            :assignees,
            :labels,
            :description,
            :hierarchy,
            :milestone,
            :notes,
            :health_status,
            :progress,
            :notifications,
            :current_user_todos,
            :award_emoji
          ],
          key_result: [
            :assignees,
            :labels,
            :description,
            :hierarchy,
            :start_and_due_date,
            :notes,
            :health_status,
            :progress,
            :notifications,
            :current_user_todos,
            :award_emoji
          ]
        }.freeze

        def self.upsert_types
          current_time = Time.current

          base_types = ::WorkItems::Type::BASE_TYPES.map do |type, attributes|
            attributes.slice(:name, :icon_name)
                      .merge(created_at: current_time, updated_at: current_time, base_type: type)
          end

          ::WorkItems::Type.upsert_all(
            base_types,
            unique_by: :idx_work_item_types_on_namespace_id_and_name_null_namespace
          )

          upsert_widgets
        end

        def self.upsert_widgets
          type_ids_by_name = ::WorkItems::Type.default.pluck(:name, :id).to_h # rubocop: disable CodeReuse/ActiveRecord

          widgets = WIDGETS_FOR_TYPE.flat_map do |type_sym, widget_syms|
            type_name = ::WorkItems::Type::TYPE_NAMES[type_sym]

            widget_syms.map do |widget_sym|
              {
                work_item_type_id: type_ids_by_name[type_name],
                name: WIDGET_NAMES[widget_sym],
                widget_type: ::WorkItems::WidgetDefinition.widget_types[widget_sym]
              }
            end
          end

          ::WorkItems::WidgetDefinition.upsert_all(
            widgets,
            unique_by: :index_work_item_widget_definitions_on_default_witype_and_name
          )
        end
      end
    end
  end
end

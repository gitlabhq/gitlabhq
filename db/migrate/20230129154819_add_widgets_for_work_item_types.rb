# frozen_string_literal: true

class AddWidgetsForWorkItemTypes < Gitlab::Database::Migration[2.1]
  class WorkItemType < MigrationRecord
    self.table_name = 'work_item_types'
  end

  class WidgetDefinition < MigrationRecord
    self.table_name = 'work_item_widget_definitions'
  end

  restrict_gitlab_migration gitlab_schema: :gitlab_main
  disable_ddl_transaction!

  def up
    widget_names = {
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
      test_reports: 'Test reports'
    }

    widgets_for_type = {
      'Issue' => [
        :assignees,
        :labels,
        :description,
        :hierarchy,
        :start_and_due_date,
        :milestone,
        :notes,
        # EE widgets
        :iteration,
        :weight,
        :health_status
      ],
      'Incident' => [
        :description,
        :hierarchy,
        :notes
      ],
      'Test Case' => [
        :description,
        :notes
      ],
      'Requirement' => [
        :description,
        :notes,
        :status,
        :requirement_legacy,
        :test_reports
      ],
      'Task' => [
        :assignees,
        :labels,
        :description,
        :hierarchy,
        :start_and_due_date,
        :milestone,
        :notes,
        :iteration,
        :weight
      ],
      'Objective' => [
        :assignees,
        :labels,
        :description,
        :hierarchy,
        :milestone,
        :notes,
        :health_status,
        :progress
      ],
      'Key Result' => [
        :assignees,
        :labels,
        :description,
        :hierarchy,
        :start_and_due_date,
        :notes,
        :health_status,
        :progress
      ]
    }

    widgets_enum = {
      assignees: 0,
      description: 1,
      hierarchy: 2,
      labels: 3,
      milestone: 4,
      notes: 5,
      start_and_due_date: 6,
      health_status: 7, # EE-only
      weight: 8, # EE-only
      iteration: 9, # EE-only
      progress: 10, # EE-only
      status: 11, # EE-only
      requirement_legacy: 12, # EE-only
      test_reports: 13
    }

    widgets = []
    widgets_for_type.each do |type_name, widget_syms|
      type = WorkItemType.find_by_name_and_namespace_id(type_name, nil)

      unless type
        Gitlab::AppLogger.warn("type #{type_name} is missing, not adding widgets")

        next
      end

      widgets += widget_syms.map do |widget_sym|
        {
          work_item_type_id: type.id,
          name: widget_names[widget_sym],
          widget_type: widgets_enum[widget_sym]
        }
      end
    end

    return if widgets.empty?

    WidgetDefinition.upsert_all(
      widgets,
      unique_by: :index_work_item_widget_definitions_on_default_witype_and_name
    )
  end

  def down
    WidgetDefinition.delete_all
  end
end

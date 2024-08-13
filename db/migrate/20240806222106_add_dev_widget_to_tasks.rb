# frozen_string_literal: true

class AddDevWidgetToTasks < Gitlab::Database::Migration[2.2]
  class WorkItemType < MigrationRecord
    self.table_name = 'work_item_types'
  end

  class WidgetDefinition < MigrationRecord
    self.table_name = 'work_item_widget_definitions'
  end

  restrict_gitlab_migration gitlab_schema: :gitlab_main
  disable_ddl_transaction!
  milestone '17.3'

  TASK_ENUM_VALUE = 4
  WIDGET_NAME = 'Development'
  WIDGET_ENUM_VALUE = 23

  class MigrationWorkItemType < MigrationRecord
    self.table_name = 'work_item_types'
  end

  class MigrationWidgetDefinition < MigrationRecord
    self.table_name = 'work_item_widget_definitions'
  end

  def up
    task_work_item_type = MigrationWorkItemType.find_by(base_type: TASK_ENUM_VALUE)

    # Task type should exist in production applications, checking here to avoid failures
    # if inconsistent data is present.
    return say('Task work item type does not exist, skipping widget creation') unless task_work_item_type

    widgets = [
      {
        work_item_type_id: task_work_item_type.id,
        name: WIDGET_NAME,
        widget_type: WIDGET_ENUM_VALUE
      }
    ]

    MigrationWidgetDefinition.upsert_all(
      widgets,
      unique_by: :index_work_item_widget_definitions_on_default_witype_and_name
    )
  end

  def down
    task_work_item_type = MigrationWorkItemType.find_by(base_type: TASK_ENUM_VALUE)

    return say('Task work item type does not exist, skipping widget removal') unless task_work_item_type

    widget_definition = MigrationWidgetDefinition.find_by(
      work_item_type_id: task_work_item_type.id,
      widget_type: WIDGET_ENUM_VALUE,
      name: WIDGET_NAME
    )

    return say('Widget definition not found, skipping widget removal') unless widget_definition

    widget_definition.destroy
  end
end

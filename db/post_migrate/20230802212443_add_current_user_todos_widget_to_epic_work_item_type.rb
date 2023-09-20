# frozen_string_literal: true

class AddCurrentUserTodosWidgetToEpicWorkItemType < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!
  restrict_gitlab_migration gitlab_schema: :gitlab_main

  EPIC_ENUM_VALUE = 7
  WIDGET_NAME = 'Current user todos'
  WIDGET_ENUM_VALUE = 15

  class MigrationWorkItemType < MigrationRecord
    self.table_name = 'work_item_types'
  end

  class MigrationWidgetDefinition < MigrationRecord
    self.table_name = 'work_item_widget_definitions'
  end

  def up
    epic_work_item_type = MigrationWorkItemType.find_by(base_type: EPIC_ENUM_VALUE, namespace_id: nil)

    # Epic type should exist in production applications, checking here to avoid failures
    # if inconsistent data is present.
    return say('Epic work item type does not exist, skipping widget creation') unless epic_work_item_type

    widgets = [
      {
        work_item_type_id: epic_work_item_type.id,
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
    epic_work_item_type = MigrationWorkItemType.find_by(base_type: EPIC_ENUM_VALUE, namespace_id: nil)

    return say('Epic work item type does not exist, skipping widget removal') unless epic_work_item_type

    widget_definition = MigrationWidgetDefinition.find_by(
      work_item_type_id: epic_work_item_type.id,
      widget_type: WIDGET_ENUM_VALUE,
      name: WIDGET_NAME,
      namespace_id: nil
    )

    return say('Widget definition not found, skipping widget removal') unless widget_definition

    widget_definition.destroy
  end
end

# frozen_string_literal: true

class AddAssigneeWidgetToIncidents < Gitlab::Database::Migration[2.1]
  class WorkItemType < MigrationRecord
    self.table_name = 'work_item_types'
  end

  class WidgetDefinition < MigrationRecord
    self.table_name = 'work_item_widget_definitions'
  end

  restrict_gitlab_migration gitlab_schema: :gitlab_main
  disable_ddl_transaction!

  WIDGET_NAME = 'Assignees'
  WIDGET_ENUM_VALUE = 0
  WORK_ITEM_TYPE = 'Incident'
  FAILURE_MSG = "type #{WORK_ITEM_TYPE} is missing, not adding widget"

  def up
    type = WorkItemType.find_by_name_and_namespace_id(WORK_ITEM_TYPE, nil)

    unless type
      say(FAILURE_MSG)
      Gitlab::AppLogger.warn(FAILURE_MSG)

      return
    end

    widgets = [{
      work_item_type_id: type.id,
      name: WIDGET_NAME,
      widget_type: WIDGET_ENUM_VALUE
    }]

    WidgetDefinition.upsert_all(
      widgets,
      unique_by: :index_work_item_widget_definitions_on_default_witype_and_name
    )
  end

  def down
    type = WorkItemType.find_by_name_and_namespace_id(WORK_ITEM_TYPE, nil)
    return unless type

    WidgetDefinition.where(work_item_type_id: type, name: WIDGET_NAME).delete_all
  end
end

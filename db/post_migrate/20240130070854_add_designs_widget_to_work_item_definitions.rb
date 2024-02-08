# frozen_string_literal: true

class AddDesignsWidgetToWorkItemDefinitions < Gitlab::Database::Migration[2.2]
  milestone '16.9'

  class WorkItemType < MigrationRecord
    self.table_name = 'work_item_types'
  end

  class WidgetDefinition < MigrationRecord
    self.table_name = 'work_item_widget_definitions'
  end

  restrict_gitlab_migration gitlab_schema: :gitlab_main
  disable_ddl_transaction!

  WIDGET_NAME = 'Designs'
  WIDGET_ENUM_VALUE = 22
  WORK_ITEM_TYPE = 'Issue'

  def up
    type = WorkItemType.find_by_name_and_namespace_id(WORK_ITEM_TYPE, nil)

    unless type
      Gitlab::AppLogger.warn("type #{WORK_ITEM_TYPE} is missing, not adding widget")
      return
    end

    widget = {
      work_item_type_id: type.id,
      name: WIDGET_NAME,
      widget_type: WIDGET_ENUM_VALUE
    }

    WidgetDefinition.upsert_all(
      [widget],
      unique_by: :index_work_item_widget_definitions_on_default_witype_and_name
    )
  end

  def down
    WidgetDefinition.where(name: WIDGET_NAME).delete_all
  end
end

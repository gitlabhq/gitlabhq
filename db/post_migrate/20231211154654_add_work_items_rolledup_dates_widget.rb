# frozen_string_literal: true

class AddWorkItemsRolledupDatesWidget < Gitlab::Database::Migration[2.2]
  milestone '16.8'

  class WorkItemType < MigrationRecord
    self.table_name = 'work_item_types'
  end

  class WidgetDefinition < MigrationRecord
    self.table_name = 'work_item_widget_definitions'
  end

  restrict_gitlab_migration gitlab_schema: :gitlab_main
  disable_ddl_transaction!

  WIDGET_NAME = 'Rolledup dates'
  WIDGET_ENUM_VALUE = 19
  WORK_ITEM_TYPES = ['Epic'].freeze

  def up
    widgets = WORK_ITEM_TYPES.each_with_object([]) do |type_name, result|
      type = WorkItemType.find_by_name_and_namespace_id(type_name, nil)

      unless type
        Gitlab::AppLogger.warn("type #{type_name} is missing, not adding widget")

        next
      end

      result << {
        work_item_type_id: type.id,
        name: WIDGET_NAME,
        widget_type: WIDGET_ENUM_VALUE
      }
    end

    return if widgets.empty?

    WidgetDefinition.upsert_all(
      widgets,
      unique_by: :index_work_item_widget_definitions_on_default_witype_and_name
    )
  end

  def down
    WidgetDefinition.where(name: WIDGET_NAME).delete_all
  end
end

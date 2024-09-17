# frozen_string_literal: true

class RemoveCrmContactsWidgetFromWorkItemTypes < Gitlab::Database::Migration[2.2]
  class WorkItemType < MigrationRecord
    self.table_name = 'work_item_types'
  end

  class WidgetDefinition < MigrationRecord
    self.table_name = 'work_item_widget_definitions'
  end

  restrict_gitlab_migration gitlab_schema: :gitlab_main
  disable_ddl_transaction!
  milestone '17.4'

  WIDGET_NAME = 'CrmContacts'
  WIDGET_ENUM_VALUE = 24
  WORK_ITEM_TYPES = %w[
    Epic
    Task
  ].freeze

  def up
    WORK_ITEM_TYPES.each do |type_name|
      type = WorkItemType.find_by_name_and_namespace_id(type_name, nil)
      next unless type

      WidgetDefinition.where(name: WIDGET_NAME, work_item_type_id: type.id).delete_all
    end
  end

  def down
    WorkItemType.reset_column_information

    widgets = []

    WORK_ITEM_TYPES.each do |type_name|
      type = WorkItemType.find_by_name_and_namespace_id(type_name, nil)

      unless type
        Gitlab::AppLogger.warn("type #{type_name} is missing, not adding widget")

        next
      end

      widgets << {
        work_item_type_id: type.id,
        name: WIDGET_NAME,
        widget_type: WIDGET_ENUM_VALUE
      }
    end

    return if widgets.empty?

    WidgetDefinition.upsert_all(
      widgets,
      on_duplicate: :skip
    )
  end
end

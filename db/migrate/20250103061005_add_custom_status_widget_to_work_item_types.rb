# frozen_string_literal: true

class AddCustomStatusWidgetToWorkItemTypes < Gitlab::Database::Migration[2.2]
  include Gitlab::Database::MigrationHelpers::WorkItems::Widgets

  restrict_gitlab_migration gitlab_schema: :gitlab_main
  disable_ddl_transaction!
  milestone '17.8'

  WORK_ITEM_TYPE_ENUM_VALUE = 4 # task
  WIDGETS = [
    {
      name: 'Custom status',
      widget_type: 26
    }
  ]

  def up
    add_widget_definitions(type_enum_value: WORK_ITEM_TYPE_ENUM_VALUE, widgets: WIDGETS)
  end

  def down
    remove_widget_definitions(type_enum_value: WORK_ITEM_TYPE_ENUM_VALUE, widgets: WIDGETS)
  end
end

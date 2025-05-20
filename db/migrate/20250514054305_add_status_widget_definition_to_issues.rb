# frozen_string_literal: true

class AddStatusWidgetDefinitionToIssues < Gitlab::Database::Migration[2.3]
  include Gitlab::Database::MigrationHelpers::WorkItems::Widgets

  restrict_gitlab_migration gitlab_schema: :gitlab_main
  disable_ddl_transaction!
  milestone '18.1'

  WORK_ITEM_TYPE_ENUM_VALUES = [0] # issues
  WIDGETS = [
    {
      name: 'Status',
      widget_type: 26
    }
  ]

  def up
    add_widget_definitions(type_enum_values: WORK_ITEM_TYPE_ENUM_VALUES, widgets: WIDGETS)
  end

  def down
    remove_widget_definitions(type_enum_values: WORK_ITEM_TYPE_ENUM_VALUES, widgets: WIDGETS)
  end
end

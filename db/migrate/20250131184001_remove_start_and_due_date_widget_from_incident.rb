# frozen_string_literal: true

class RemoveStartAndDueDateWidgetFromIncident < Gitlab::Database::Migration[2.2]
  include Gitlab::Database::MigrationHelpers::WorkItems::Widgets

  restrict_gitlab_migration gitlab_schema: :gitlab_main
  disable_ddl_transaction!
  milestone '17.9'

  WORK_ITEM_TYPE_ENUM_VALUES = [1] # incident
  WIDGETS = [
    {
      name: 'Start and due date',
      widget_type: 6
    }
  ]

  def up
    remove_widget_definitions(type_enum_values: WORK_ITEM_TYPE_ENUM_VALUES, widgets: WIDGETS)
  end

  def down
    add_widget_definitions(type_enum_values: WORK_ITEM_TYPE_ENUM_VALUES, widgets: WIDGETS)
  end
end

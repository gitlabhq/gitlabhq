# frozen_string_literal: true

class AddLinkedResourcesWidgetToWorkItemTypesV2 < Gitlab::Database::Migration[2.3]
  include Gitlab::Database::MigrationHelpers::WorkItems::Widgets

  restrict_gitlab_migration gitlab_schema: :gitlab_main
  disable_ddl_transaction!
  milestone '18.2'

  WORK_ITEM_TYPE_ENUM_VALUES = [0, 1, 4] # issue, incident, task

  WIDGETS = [
    {
      name: 'LinkedResources',
      widget_type: 27
    }
  ]

  def up
    add_widget_definitions(type_enum_values: WORK_ITEM_TYPE_ENUM_VALUES, widgets: WIDGETS)
  end

  def down
    remove_widget_definitions(type_enum_values: WORK_ITEM_TYPE_ENUM_VALUES, widgets: WIDGETS)
  end
end

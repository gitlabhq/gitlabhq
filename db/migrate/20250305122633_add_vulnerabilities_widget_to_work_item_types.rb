# frozen_string_literal: true

class AddVulnerabilitiesWidgetToWorkItemTypes < Gitlab::Database::Migration[2.2]
  include Gitlab::Database::MigrationHelpers::WorkItems::Widgets

  restrict_gitlab_migration gitlab_schema: :gitlab_main
  disable_ddl_transaction!
  milestone '17.10'

  WORK_ITEM_TYPE_ENUM_VALUES = [0] # issue

  WIDGETS = [
    {
      name: 'Vulnerabilities',
      widget_type: 30
    }
  ]

  def up
    add_widget_definitions(type_enum_values: WORK_ITEM_TYPE_ENUM_VALUES, widgets: WIDGETS)
  end

  def down
    remove_widget_definitions(type_enum_values: WORK_ITEM_TYPE_ENUM_VALUES, widgets: WIDGETS)
  end
end

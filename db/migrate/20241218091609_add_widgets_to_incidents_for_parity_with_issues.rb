# frozen_string_literal: true

class AddWidgetsToIncidentsForParityWithIssues < Gitlab::Database::Migration[2.2]
  include Gitlab::Database::MigrationHelpers::WorkItems::Widgets

  restrict_gitlab_migration gitlab_schema: :gitlab_main
  disable_ddl_transaction!
  milestone '17.8'

  WORK_ITEM_TYPE_ENUM_VALUE = 1 # incident
  WIDGETS = [
    {
      name: 'Labels',
      widget_type: 3
    },
    {
      name: 'Milestone',
      widget_type: 4
    },
    {
      name: 'Start and due date',
      widget_type: 6
    },
    {
      name: 'Iteration',
      widget_type: 9
    }
  ]

  def up
    add_widget_definitions(type_enum_value: WORK_ITEM_TYPE_ENUM_VALUE, widgets: WIDGETS)
  end

  def down
    remove_widget_definitions(type_enum_value: WORK_ITEM_TYPE_ENUM_VALUE, widgets: WIDGETS)
  end
end

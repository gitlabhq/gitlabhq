# frozen_string_literal: true

class AddCustomFieldsWidgetToWorkItemTypes < Gitlab::Database::Migration[2.2]
  include Gitlab::Database::MigrationHelpers::WorkItems::Widgets

  restrict_gitlab_migration gitlab_schema: :gitlab_main
  disable_ddl_transaction!
  milestone '17.9'

  WORK_ITEM_TYPE_ENUM_VALUES = [
    0, # issue
    1, # incident
    2, # test_case
    3, # requirement
    4, # task
    5, # objective
    6, # key_result
    7, # epic
    8  # ticket
  ]

  WIDGETS = [
    {
      name: 'Custom fields',
      widget_type: 28
    }
  ]

  def up
    add_widget_definitions(type_enum_values: WORK_ITEM_TYPE_ENUM_VALUES, widgets: WIDGETS)
  end

  def down
    remove_widget_definitions(type_enum_values: WORK_ITEM_TYPE_ENUM_VALUES, widgets: WIDGETS)
  end
end

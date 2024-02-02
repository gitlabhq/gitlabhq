# frozen_string_literal: true

class AddTimeTrackingWidgetDefinitionToWorkItemTypes < Gitlab::Database::Migration[2.2]
  milestone '16.9'

  restrict_gitlab_migration gitlab_schema: :gitlab_main
  disable_ddl_transaction!

  WIDGET_NAME = 'Time Tracking'
  WIDGET_ENUM_VALUE = 21

  # WorkItemTypes that would support Time tracking are provided in: https://gitlab.com/groups/gitlab-org/-/epics/12396
  WORK_ITEM_TYPES = [
    "Issue",
    "Task",
    "Epic",
    "Requirement",
    "Test Case",
    "Ticket",
    "Incident"
  ].freeze

  class WorkItemType < MigrationRecord
    self.table_name = 'work_item_types'
    self.inheritance_column = :_type_disabled
  end

  def up
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

    work_item_widget_definitions.upsert_all(
      widgets,
      unique_by: :index_work_item_widget_definitions_on_default_witype_and_name
    )
  end

  def down
    work_item_widget_definitions.where(name: WIDGET_NAME).delete_all
  end

  private

  def work_item_widget_definitions
    define_batchable_model('work_item_widget_definitions')
  end
end

# frozen_string_literal: true

class CleanTimeTrackingWidgetDefinitions < Gitlab::Database::Migration[2.2]
  milestone '17.4'

  restrict_gitlab_migration gitlab_schema: :gitlab_main

  WIDGET_NAME = 'Time tracking'
  WIDGET_ENUM_VALUE = 21

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
    # Time tracking widget definition was introduced with the wrong casing initially in the migration
    # https://gitlab.com/gitlab-org/gitlab/-/merge_requests/142329
    # so we are recreating them with the correct casing. A new index will be added which ignores casing.
    # Casing needs to match in lib/gitlab/database_importers/work_items/base_type_importer.rb
    work_item_widget_definitions.where(widget_type: WIDGET_ENUM_VALUE).delete_all

    widgets = []

    WORK_ITEM_TYPES.each do |type_name|
      type = WorkItemType.find_by_name(type_name)

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
    # no-op we don't want to put widget definitions back in the wrong state
  end

  private

  def work_item_widget_definitions
    @work_item_widget_definitions ||= define_batchable_model('work_item_widget_definitions')
  end
end

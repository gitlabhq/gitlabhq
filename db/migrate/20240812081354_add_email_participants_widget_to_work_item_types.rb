# frozen_string_literal: true

class AddEmailParticipantsWidgetToWorkItemTypes < Gitlab::Database::Migration[2.2]
  class WorkItemType < MigrationRecord
    self.table_name = 'work_item_types'
  end

  class WidgetDefinition < MigrationRecord
    self.table_name = 'work_item_widget_definitions'
  end

  restrict_gitlab_migration gitlab_schema: :gitlab_main
  disable_ddl_transaction!
  milestone '17.4'

  WIDGET_NAME = 'Email participants'
  WIDGET_ENUM_VALUE = 25
  WORK_ITEM_TYPES = %w[
    Incident
    Issue
    Ticket
  ].freeze

  def up
    widgets = WorkItemType.where(name: WORK_ITEM_TYPES).map do |type|
      { work_item_type_id: type.id, name: WIDGET_NAME, widget_type: WIDGET_ENUM_VALUE }
    end

    return if widgets.empty?

    WidgetDefinition.upsert_all(
      widgets,
      unique_by: :index_work_item_widget_definitions_on_default_witype_and_name
    )
  end

  def down
    WidgetDefinition.where(widget_type: WIDGET_ENUM_VALUE).delete_all
  end
end

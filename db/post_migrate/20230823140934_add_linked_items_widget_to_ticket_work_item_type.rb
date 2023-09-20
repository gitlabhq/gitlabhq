# frozen_string_literal: true

class AddLinkedItemsWidgetToTicketWorkItemType < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!
  restrict_gitlab_migration gitlab_schema: :gitlab_main

  TICKET_ENUM_VALUE = 8
  WIDGET_NAME = 'Linked items'
  WIDGET_ENUM_VALUE = 17

  class MigrationWorkItemType < MigrationRecord
    self.table_name = 'work_item_types'
  end

  class MigrationWidgetDefinition < MigrationRecord
    self.table_name = 'work_item_widget_definitions'
  end

  def up
    # New instances will not run this migration and add this type via fixtures
    # checking if record exists mostly because migration specs will run all migrations
    # and that will conflict with the preloaded base work item types
    ticket_work_item_type = MigrationWorkItemType.find_by(base_type: TICKET_ENUM_VALUE, namespace_id: nil)

    return say('Ticket work item type does not exist, skipping widget creation') unless ticket_work_item_type

    widgets = [
      {
        work_item_type_id: ticket_work_item_type.id,
        name: WIDGET_NAME,
        widget_type: WIDGET_ENUM_VALUE
      }
    ]

    MigrationWidgetDefinition.upsert_all(
      widgets,
      unique_by: :index_work_item_widget_definitions_on_default_witype_and_name
    )
  end

  def down
    ticket_work_item_type = MigrationWorkItemType.find_by(base_type: TICKET_ENUM_VALUE, namespace_id: nil)

    return say('Ticket work item type does not exist, skipping widget removal') unless ticket_work_item_type

    MigrationWidgetDefinition.where(work_item_type_id: ticket_work_item_type.id, widget_type: WIDGET_ENUM_VALUE)
                             .delete_all
  end
end

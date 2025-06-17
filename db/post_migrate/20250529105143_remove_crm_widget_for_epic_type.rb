# frozen_string_literal: true

class RemoveCrmWidgetForEpicType < Gitlab::Database::Migration[2.3]
  CRM_WIDGET_ID = 24
  EPIC_ID = 8

  disable_ddl_transaction!
  restrict_gitlab_migration gitlab_schema: :gitlab_main

  milestone '18.1'

  class MigrationWorkItemWidgetDefinition < MigrationRecord
    self.table_name = 'work_item_widget_definitions'
  end

  def up
    MigrationWorkItemWidgetDefinition.where(widget_type: CRM_WIDGET_ID, work_item_type_id: EPIC_ID).delete_all
  end

  def down
    # no-op as rebuilding the type and associated records is a lot of information to put on a migration file.
    # If anyone needs to rollback this change in dev environments, they can use an importer to upsert type information
    # using the following commands in a Rails console:
    #
    # Gitlab::DatabaseImporters::WorkItems::BaseTypeImporter.upsert_types
  end
end

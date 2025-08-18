# frozen_string_literal: true

class DropBulkImportTrackersProjectIdTrigger < Gitlab::Database::Migration[2.3]
  milestone '18.4'

  def up
    remove_sharding_key_assignment_trigger(
      table: :bulk_import_trackers,
      sharding_key: :project_id,
      parent_table: :bulk_import_entities,
      parent_sharding_key: :project_id,
      foreign_key: :bulk_import_entity_id,
      trigger_name: 'trigger_7f84f9c7b945'
    )
  end

  def down
    install_sharding_key_assignment_trigger(
      table: :bulk_import_trackers,
      sharding_key: :project_id,
      parent_table: :bulk_import_entities,
      parent_sharding_key: :project_id,
      foreign_key: :bulk_import_entity_id,
      trigger_name: 'trigger_7f84f9c7b945'
    )
  end
end

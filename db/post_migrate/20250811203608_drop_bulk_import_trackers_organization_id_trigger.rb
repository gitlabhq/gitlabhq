# frozen_string_literal: true

class DropBulkImportTrackersOrganizationIdTrigger < Gitlab::Database::Migration[2.3]
  milestone '18.4'

  def up
    remove_sharding_key_assignment_trigger(
      table: :bulk_import_trackers,
      sharding_key: :organization_id,
      parent_table: :bulk_import_entities,
      parent_sharding_key: :organization_id,
      foreign_key: :bulk_import_entity_id,
      trigger_name: 'trigger_765cae42cd77'
    )
  end

  def down
    install_sharding_key_assignment_trigger(
      table: :bulk_import_trackers,
      sharding_key: :organization_id,
      parent_table: :bulk_import_entities,
      parent_sharding_key: :organization_id,
      foreign_key: :bulk_import_entity_id,
      trigger_name: 'trigger_765cae42cd77'
    )
  end
end

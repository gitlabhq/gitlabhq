# frozen_string_literal: true

class AddAuditEventsGroupIndex < Gitlab::Database::Migration[2.1]
  include Gitlab::Database::PartitioningMigrationHelpers

  TABLE_NAME = :audit_events
  COLUMN_NAMES = [:entity_id, :entity_type, :created_at, :id]
  INDEX_NAME = 'index_audit_events_on_entity_id_and_entity_type_and_created_at'

  disable_ddl_transaction!

  def up
    add_concurrent_partitioned_index(TABLE_NAME, COLUMN_NAMES, name: INDEX_NAME)
  end

  def down
    remove_concurrent_partitioned_index_by_name(TABLE_NAME, INDEX_NAME)
  end
end

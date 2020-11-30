# frozen_string_literal: true

class AddPartitionedAuditEventIndexes < ActiveRecord::Migration[6.0]
  include Gitlab::Database::PartitioningMigrationHelpers

  DOWNTIME = false

  CREATED_AT_AUTHOR_ID_INDEX_NAME = 'analytics_index_audit_events_part_on_created_at_and_author_id'
  ENTITY_ID_DESC_INDEX_NAME = 'idx_audit_events_part_on_entity_id_desc_author_id_created_at'

  disable_ddl_transaction!

  def up
    add_concurrent_partitioned_index :audit_events_part_5fc467ac26,
      [:created_at, :author_id],
      name: CREATED_AT_AUTHOR_ID_INDEX_NAME

    add_concurrent_partitioned_index :audit_events_part_5fc467ac26,
      [:entity_id, :entity_type, :id, :author_id, :created_at],
      order: { id: :desc },
      name: ENTITY_ID_DESC_INDEX_NAME
  end

  def down
    remove_concurrent_partitioned_index_by_name :audit_events_part_5fc467ac26, ENTITY_ID_DESC_INDEX_NAME

    remove_concurrent_partitioned_index_by_name :audit_events_part_5fc467ac26, CREATED_AT_AUTHOR_ID_INDEX_NAME
  end
end

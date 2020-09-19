# frozen_string_literal: true

class AddCreatedAtIndexToAuditEvents < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  INDEX_NAME = 'idx_audit_events_on_entity_id_desc_author_id_created_at'
  OLD_INDEX_NAME = 'index_audit_events_on_entity_id_entity_type_id_desc_author_id'

  def up
    add_concurrent_index(:audit_events, [:entity_id, :entity_type, :id, :author_id, :created_at], order: { id: :desc }, name: INDEX_NAME)
    remove_concurrent_index_by_name(:audit_events, OLD_INDEX_NAME)
  end

  def down
    add_concurrent_index(:audit_events, [:entity_id, :entity_type, :id, :author_id], order: { id: :desc }, name: OLD_INDEX_NAME)
    remove_concurrent_index_by_name(:audit_events, INDEX_NAME)
  end
end

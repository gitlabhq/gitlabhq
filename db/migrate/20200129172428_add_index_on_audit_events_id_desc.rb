# frozen_string_literal: true

class AddIndexOnAuditEventsIdDesc < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  OLD_INDEX_NAME = 'index_audit_events_on_entity_id_and_entity_type'
  NEW_INDEX_NAME = 'index_audit_events_on_entity_id_and_entity_type_and_id_desc'

  disable_ddl_transaction!

  def up
    add_concurrent_index :audit_events, [:entity_id, :entity_type, :id], name: NEW_INDEX_NAME,
      order: { entity_id: :asc, entity_type: :asc, id: :desc }

    remove_concurrent_index_by_name :audit_events, OLD_INDEX_NAME
  end

  def down
    add_concurrent_index :audit_events, [:entity_id, :entity_type], name: OLD_INDEX_NAME

    remove_concurrent_index_by_name :audit_events, NEW_INDEX_NAME
  end
end

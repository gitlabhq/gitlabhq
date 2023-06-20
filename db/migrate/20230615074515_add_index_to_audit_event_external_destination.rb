# frozen_string_literal: true

class AddIndexToAuditEventExternalDestination < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  INDEX_NAME = 'unique_external_audit_event_destination_namespace_id_and_name'

  def up
    add_concurrent_index :audit_events_external_audit_event_destinations, [:namespace_id, :name], unique: true,
      name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :audit_events_external_audit_event_destinations, INDEX_NAME
  end
end

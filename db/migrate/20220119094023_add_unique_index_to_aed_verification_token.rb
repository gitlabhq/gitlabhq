# frozen_string_literal: true

class AddUniqueIndexToAedVerificationToken < Gitlab::Database::Migration[1.0]
  disable_ddl_transaction!

  INDEX_NAME = 'index_audit_events_external_audit_on_verification_token'

  def up
    add_concurrent_index :audit_events_external_audit_event_destinations, :verification_token, unique: true, name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :audit_events_external_audit_event_destinations, INDEX_NAME
  end
end

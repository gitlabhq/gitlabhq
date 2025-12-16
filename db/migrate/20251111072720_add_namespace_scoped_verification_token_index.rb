# frozen_string_literal: true

class AddNamespaceScopedVerificationTokenIndex < Gitlab::Database::Migration[2.3]
  milestone '18.7'

  disable_ddl_transaction!

  TABLE_NAME = :audit_events_external_audit_event_destinations
  OLD_INDEX_NAME = :index_audit_events_external_audit_on_verification_token
  NEW_INDEX_NAME = :index_audit_events_external_audit_on_ns_verification_token
  COLUMNS = [:namespace_id, :verification_token]

  def up
    add_concurrent_index(
      TABLE_NAME,
      COLUMNS,
      unique: true,
      name: NEW_INDEX_NAME
    )

    remove_concurrent_index_by_name(
      TABLE_NAME,
      OLD_INDEX_NAME
    )
  end

  def down; end
end

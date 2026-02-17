# frozen_string_literal: true

class AddInstanceStreamingDestinationsSecretTokenLengthConstraint < Gitlab::Database::Migration[2.3]
  milestone '18.9'

  disable_ddl_transaction!

  ENCRYPTED_LIMIT = 4096 + 16
  CONSTRAINT_NAME = 'check_audit_event_streams_instance_secret_token_max_length'
  TABLE_NAME = :audit_events_instance_external_streaming_destinations

  def up
    add_check_constraint(
      TABLE_NAME,
      "octet_length(encrypted_secret_token) <= #{ENCRYPTED_LIMIT}",
      CONSTRAINT_NAME
    )
  end

  def down
    remove_check_constraint(TABLE_NAME, CONSTRAINT_NAME)
  end
end

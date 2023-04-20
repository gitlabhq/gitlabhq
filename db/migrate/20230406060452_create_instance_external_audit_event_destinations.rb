# frozen_string_literal: true

class CreateInstanceExternalAuditEventDestinations < Gitlab::Database::Migration[2.1]
  enable_lock_retries!

  def change
    create_table :audit_events_instance_external_audit_event_destinations do |t|
      t.timestamps_with_timezone null: false
      t.text :destination_url, null: false, limit: 255 # rubocop:disable Migration/AddLimitToTextColumns
      t.binary :encrypted_verification_token, null: false
      t.binary :encrypted_verification_token_iv, null: false
    end
  end
end

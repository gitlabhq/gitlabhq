# frozen_string_literal: true

class AddTextLimitToExadVerificationTokens < Gitlab::Database::Migration[1.0]
  disable_ddl_transaction!

  def up
    add_text_limit :audit_events_external_audit_event_destinations, :verification_token, 24
  end

  def down
    remove_text_limit :audit_events_external_audit_event_destinations, :verification_token
  end
end

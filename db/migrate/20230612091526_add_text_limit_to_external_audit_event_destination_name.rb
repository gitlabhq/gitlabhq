# frozen_string_literal: true

class AddTextLimitToExternalAuditEventDestinationName < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  def up
    add_text_limit :audit_events_external_audit_event_destinations, :name, 72
  end

  def down
    remove_text_limit :audit_events_external_audit_event_destinations, :name
  end
end

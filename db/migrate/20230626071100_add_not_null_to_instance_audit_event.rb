# frozen_string_literal: true

class AddNotNullToInstanceAuditEvent < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  def up
    change_column_null :audit_events_instance_external_audit_event_destinations, :name, false
  end

  def down
    change_column_null :audit_events_instance_external_audit_event_destinations, :name, true
  end
end

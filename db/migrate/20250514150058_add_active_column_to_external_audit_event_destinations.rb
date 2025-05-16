# frozen_string_literal: true

class AddActiveColumnToExternalAuditEventDestinations < Gitlab::Database::Migration[2.3]
  milestone '18.1'

  def up
    add_column :audit_events_external_audit_event_destinations, :active, :boolean, null: false, default: true
  end

  def down
    remove_column :audit_events_external_audit_event_destinations, :active
  end
end

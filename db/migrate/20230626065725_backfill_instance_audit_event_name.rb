# frozen_string_literal: true

class BackfillInstanceAuditEventName < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_main

  class InstanceDestination < MigrationRecord
    self.table_name = 'audit_events_instance_external_audit_event_destinations'
  end

  def change
    InstanceDestination.update_all("name = 'Destination ' || id")
  end
end

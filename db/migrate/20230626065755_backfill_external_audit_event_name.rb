# frozen_string_literal: true

class BackfillExternalAuditEventName < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_main

  class ExternalDestination < MigrationRecord
    self.table_name = 'audit_events_external_audit_event_destinations'
  end

  def change
    ExternalDestination.update_all("name = 'Destination ' || id")
  end
end

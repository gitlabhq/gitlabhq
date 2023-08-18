# frozen_string_literal: true

class BackfillGoogleCloudLoggingName < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_main

  class GoogleCloudLoggingConfiguration < MigrationRecord
    self.table_name = 'audit_events_google_cloud_logging_configurations'
  end

  def up
    GoogleCloudLoggingConfiguration.update_all("name = 'Destination ' || id")
  end

  def down
    # noop
  end
end

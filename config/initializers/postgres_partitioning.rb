# frozen_string_literal: true

Gitlab::Database::Partitioning.register_models([
  AuditEvent,
  WebHookLog
])

if Gitlab.ee?
  Gitlab::Database::Partitioning.register_models([
    IncidentManagement::PendingEscalations::Alert,
    IncidentManagement::PendingEscalations::Issue
  ])
else
  Gitlab::Database::Partitioning.register_tables([
    {
      table_name: 'incident_management_pending_alert_escalations',
      partitioned_column: :process_at, strategy: :monthly
    },
    {
      table_name: 'incident_management_pending_issue_escalations',
      partitioned_column: :process_at, strategy: :monthly
    }
  ])
end

# The following tables are already defined as models
unless Gitlab.jh?
  Gitlab::Database::Partitioning.register_tables([
    # This should be synchronized with the following model:
    # https://gitlab.com/gitlab-jh/gitlab/-/blob/main-jh/jh/app/models/phone/verification_code.rb
    {
      table_name: 'verification_codes',
      partitioned_column: :created_at, strategy: :monthly
    }
  ])
end

begin
  Gitlab::Database::Partitioning.sync_partitions unless ENV['DISABLE_POSTGRES_PARTITION_CREATION_ON_STARTUP']
rescue ActiveRecord::ActiveRecordError, PG::Error
  # ignore - happens when Rake tasks yet have to create a database, e.g. for testing
end

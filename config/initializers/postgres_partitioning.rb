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
end

begin
  Gitlab::Database::Partitioning.sync_partitions unless ENV['DISABLE_POSTGRES_PARTITION_CREATION_ON_STARTUP']
rescue ActiveRecord::ActiveRecordError, PG::Error
  # ignore - happens when Rake tasks yet have to create a database, e.g. for testing
end

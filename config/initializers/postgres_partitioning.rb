# frozen_string_literal: true

# Make sure we have loaded partitioned models here
# (even with eager loading disabled).

Gitlab::Database::Partitioning::PartitionManager.register(AuditEvent)
Gitlab::Database::Partitioning::PartitionManager.register(WebHookLog)

if Gitlab.ee?
  Gitlab::Database::Partitioning::PartitionManager.register(IncidentManagement::PendingEscalations::Alert)
end

begin
  Gitlab::Database::Partitioning::PartitionManager.new.sync_partitions unless ENV['DISABLE_POSTGRES_PARTITION_CREATION_ON_STARTUP']
rescue ActiveRecord::ActiveRecordError, PG::Error
  # ignore - happens when Rake tasks yet have to create a database, e.g. for testing
end

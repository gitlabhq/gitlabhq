# frozen_string_literal: true

# On .com partitions are not created on application startup,
# they are created by the PartitionManagementWorker cron worker
# which is executed several times per day. If a partition must be present
# on startup, it could be created using a regular migration.
# https://gitlab.com/gitlab-com/gl-infra/production/-/issues/2446

Gitlab::Database::Partitioning.register_models(
  [
    AuditEvent,
    AuditEvents::UserAuditEvent,
    AuditEvents::GroupAuditEvent,
    AuditEvents::ProjectAuditEvent,
    AuditEvents::InstanceAuditEvent,
    BatchedGitRefUpdates::Deletion,
    Ci::BuildMetadata,
    Ci::BuildExecutionConfig,
    Ci::BuildName,
    Ci::BuildTag,
    Ci::BuildTraceMetadata,
    Ci::BuildSource,
    Ci::Catalog::Resources::Components::Usage,
    Ci::Catalog::Resources::SyncEvent,
    Ci::FinishedPipelineChSyncEvent,
    Ci::JobAnnotation,
    Ci::JobArtifact,
    Ci::JobArtifactReport,
    Ci::Pipeline,
    Ci::PipelineConfig,
    Ci::PipelineVariable,
    Ci::RunnerManagerBuild,
    Ci::Stage,
    CommitStatus,
    Gitlab::Database::BackgroundMigration::BatchedJobTransitionLog,
    LooseForeignKeys::DeletedRecord,
    Users::GroupVisit,
    Users::ProjectVisit
    # WebHookLog is temporarily removed from this list and managed without a model
    # during the switch from web_hook_logs to web_hook_logs_daily
  ])

if Gitlab.ee?
  Gitlab::Database::Partitioning.register_models(
    [
      IncidentManagement::PendingEscalations::Alert,
      IncidentManagement::PendingEscalations::Issue,
      Security::Finding,
      Analytics::ValueStreamDashboard::Count,
      Ci::FinishedBuildChSyncEvent,
      Search::Zoekt::Task,
      Ai::CodeSuggestionEvent,
      Ai::DuoChatEvent,
      Vulnerabilities::Archive,
      Vulnerabilities::ArchivedRecord,
      Vulnerabilities::ArchiveExport
    ])
else
  Gitlab::Database::Partitioning.register_tables(
    [
      {
        limit_connection_names: %i[main],
        table_name: 'incident_management_pending_alert_escalations',
        partitioned_column: :process_at, strategy: :monthly
      },
      {
        limit_connection_names: %i[main],
        table_name: 'incident_management_pending_issue_escalations',
        partitioned_column: :process_at, strategy: :monthly
      }
    ])
end

# The following tables are already defined as models
unless Gitlab.jh?
  Gitlab::Database::Partitioning.register_tables(
    [
      # This should be synchronized with the following model:
      # https://jihulab.com/gitlab-cn/gitlab/-/blob/main-jh/jh/app/models/phone/verification_code.rb
      {
        limit_connection_names: %i[main],
        table_name: 'verification_codes',
        partitioned_column: :created_at, strategy: :monthly
      }
    ])
end

# Enable partition management for the backfill table during web_hook_logs partitioning.
# This way new partitions will be created as the trigger syncs new rows across to this table.
# We're controlling the table backing WebHookLog with the feature flag web_hook_logs_daily_enabled.
# So that the feature flag does not interact with the partition manager, register both web_hook_logs tables here,
# disconnected from the feature flag.
Gitlab::Database::Partitioning.register_tables(
  [
    {
      limit_connection_names: %i[main],
      table_name: 'web_hook_logs_daily',
      partitioned_column: :created_at, strategy: :daily, retain_for: 14.days
    },
    {
      limit_connection_names: %i[main],
      table_name: 'web_hook_logs',
      partitioned_column: :created_at, strategy: :monthly, retain_for: 1.month
    }
  ]
)

Gitlab::Database::Partitioning.sync_partitions_ignore_db_error

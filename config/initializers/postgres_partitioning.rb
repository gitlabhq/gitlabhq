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
    Ci::Catalog::Resources::SyncEvent,
    Ci::FinishedPipelineChSyncEvent,
    Ci::JobAnnotation,
    Ci::JobArtifact,
    Ci::JobArtifactReport,
    Ci::JobDefinition,
    Ci::JobDefinitionInstance,
    Ci::JobInput,
    Ci::JobMessage,
    Ci::Pipeline,
    Ci::PipelineVariable,
    Ci::RunnerManagerBuild,
    Ci::Stage,
    Ci::Workloads::Workload,
    Ci::Workloads::VariableInclusions,
    CommitStatus,
    Gitlab::Database::BackgroundMigration::BatchedJobTransitionLog,
    LooseForeignKeys::DeletedRecord,
    PartitionedSentNotification,
    Users::GroupVisit,
    Users::ProjectVisit,
    MergeRequest::CommitsMetadata,
    WebHookLog,
    MergeRequests::GeneratedRefCommit
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
      Ai::TroubleshootJobEvent,
      Ai::UsageEvent,
      Vulnerabilities::Archive,
      Vulnerabilities::ArchivedRecord,
      Vulnerabilities::ArchiveExport,
      Ai::ActiveContext::Code::EnabledNamespace,
      Ai::ActiveContext::Code::Repository,
      Ai::KnowledgeGraph::EnabledNamespace,
      Ai::KnowledgeGraph::Replica,
      Ai::KnowledgeGraph::Task,
      Ai::DuoWorkflows::Checkpoint
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

Gitlab::Database::Partitioning.sync_partitions_ignore_db_error

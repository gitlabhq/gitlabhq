---
stage: AI-powered
group: AI Core Infra
info: Any user with at least the Maintainer role can merge updates to this content. For details, see <https://docs.gitlab.com/development/development_processes/#development-guidelines-review>.
title: GitLab Duo Agent Platform observability (Rails)
---

The GitLab Duo Agent Platform (formerly GitLab Duo Workflow Service) uses the following monitoring and observability instrumentation in the GitLab Rails monolith.
Workhorse-side instrumentation is not covered.

## Prometheus metrics

### Existing metrics

All three metrics live in `ProcessAuditEventsWorker`
(`ee/app/workers/ai/duo_workflows/process_audit_events_worker.rb`) and track
AI audit event persistence only.

| Metric name | Type | Labels | What it tracks |
| --- | --- | --- | --- |
| `gitlab_ai_audit_events_buffered_total` | Counter | none | AI audit events enqueued to the ClickHouse Redis write buffer |
| `gitlab_ai_audit_events_pg_fallback_total` | Counter | none | AI audit events stored by PostgreSQL when ClickHouse is unavailable |
| `gitlab_ai_audit_events_stored_total` | Counter | `store: :postgresql` | AI audit events durably written to PostgreSQL |

### Missing metrics (gaps to address)

The following are important signals that have no Prometheus coverage.
Internal events exist for some of them, but those feed analytics pipelines, not alerting or dashboards.

| Signal | Suggested metric name | Type | Suggested labels |
| --- | --- | --- | --- |
| Session lifecycle transitions (created, started, finished, stopped, dropped, resumed) | `gitlab_duo_agent_platform_sessions_total` | Counter | `status` |
| Stuck sessions cleaned up by cron | `gitlab_duo_agent_platform_stuck_sessions_total` | Counter | none |
| Workflow execution start, finish, retry | `gitlab_duo_agent_platform_workflow_executions_total` | Counter | `event` (start, finish, retry) |
| CI workload pipeline completion | `gitlab_duo_agent_platform_workload_pipelines_total` | Counter | `status`, `workflow_definition` |
| CI workload pipeline duration | `gitlab_duo_agent_platform_workload_pipeline_duration_seconds` | Histogram | `status`, `workflow_definition` |
| Model Context Protocol (MCP) tool call start and finish | `gitlab_duo_agent_platform_mcp_tool_calls_total` | Counter | `tool_name`, `success` |
| MCP tool call duration | `gitlab_duo_agent_platform_mcp_tool_call_duration_seconds` | Histogram | `tool_name` |
| gRPC calls to GitLab Duo Workflow Service (latency and errors) | `gitlab_duo_workflow_service_grpc_requests_total` and `gitlab_duo_workflow_service_grpc_request_duration_seconds` | Counter and Histogram | `method`, `status` |
| `POST /ai/duo_workflows/direct_access` rate limit hits | `gitlab_duo_agent_platform_rate_limit_hits_total` | Counter | `endpoint` |
| Vulnerability workflow triggers | `gitlab_duo_agent_platform_vulnerability_workflow_triggers_total` | Counter | `workflow_definition` |
| GraphQL `duoWorkflowWorkflows` query calls (executor polling) | `gitlab_duo_agent_platform_graphql_workflow_queries_total` | Counter | `status` (success, error) |
| GraphQL `toolCallApproved` field resolutions | `gitlab_duo_agent_platform_tool_call_approved_checks_total` | Counter | `approved` (true/false) |
| GraphQL `WorkflowEventsUpdated` subscription connections | `gitlab_duo_agent_platform_graphql_subscriptions_total` | Counter | `event` (subscribe, unsubscribe) |
| GraphQL mutations (`create`, `deleteWorkflow`, `updateAgentPrivileges`, `updateToolCallApprovals`) | `gitlab_duo_agent_platform_graphql_mutations_total` | Counter | `mutation`, `status` |

## Internal events (GitLab Analytics / Snowplow)

These feed product analytics and are not suitable for alerting or service-level objectives (SLOs).
All event definitions live under `ee/config/events/`.

### Session lifecycle

All carry `label` (flow type, for example `chat`), `property` (environment, for example `web`),
and `value` (session ID). Identifiers: `user`, `project`, `namespace`.

| Event | Trigger location | What it tracks |
| --- | --- | --- |
| `agent_platform_session_created` | `WorkflowEventTracking` concern | Session record created |
| `agent_platform_session_started` | `WorkflowEventTracking` concern | Session started by executor |
| `agent_platform_session_finished` | `WorkflowEventTracking` concern | Session finished cleanly |
| `agent_platform_session_stopped` | `WorkflowEventTracking` concern | Session stopped by user |
| `agent_platform_session_dropped` | `WorkflowEventTracking` concern | Session dropped on error |
| `agent_platform_session_resumed` | `WorkflowEventTracking` concern | Session resumed after pause |
| `cleanup_stuck_agent_platform_session` | `CleanStuckWorkflowsService` | Stuck session cleaned up by cron. `property` = new status |

### Workflow execution

Carry `label` (workflow type), `property` (request ID), `workflow_id`. Identifier: `user`.

| Event | Trigger location | What it tracks |
| --- | --- | --- |
| `start_duo_workflow_execution` | `WorkflowEventTracking` concern | Workflow execution started |
| `finish_duo_workflow_execution` | `WorkflowEventTracking` concern | Workflow execution finished |
| `retry_duo_workflow_execution` | `WorkflowEventTracking` concern | Workflow retried |

### CI workload completion

Fired in `WorkloadMetrics` concern
(`ee/app/services/ai/duo_workflows/concerns/workload_metrics.rb`),
triggered by `UpdateWorkflowStatusEventWorker`. Also has an extra tracker
(`Gitlab::Tracking::AiTracking`).

| Event | Additional properties | What it tracks |
| --- | --- | --- |
| `duo_workflow_workload_completed` | `label` = pipeline status, `property` = build failure reason, `value` = pipeline duration in seconds, `workflow_id`, `workflow_definition` | CI pipeline for a workload completed (success or failure) |

### MCP tool calls

Carry `tool_name`, `session_id`, `duo_add_on`. Identifiers: `user`, `namespace`.
Also have an extra tracker (`Gitlab::Tracking::AiTracking`).

| Event | Additional properties | What it tracks |
| --- | --- | --- |
| `start_mcp_tool_call` | none | MCP tool call started |
| `finish_mcp_tool_call` | `has_tool_call_success`, `failure_reason`, `error_status` | MCP tool call finished |

### Vulnerability workflow triggers

Fired in `Workflows#track_event`
(`ee/lib/api/ai/duo_workflows/workflows.rb`) only when the workflow definition
matches a known vulnerability workflow.

| Event | Workflow definition | What it tracks |
| --- | --- | --- |
| `trigger_sast_vulnerability_fp_detection_workflow` | Static Application Security Testing (SAST) FP detection | SAST false-positive detection workflow triggered |
| `trigger_sast_vulnerability_resolution_workflow` | SAST resolution | SAST resolution workflow triggered |
| `trigger_secret_detection_vulnerability_fp_detection_workflow` | Secret detection FP | Secret detection false-positive workflow triggered |

## GraphQL API

The `duoWorkflowWorkflows` field is exposed on both the root query type and
`ProjectType`.
The `duoWorkflowWorkflows` field is the primary interface used by the GitLab Duo Workflow Service executor to poll session state on every execution cycle.

The GraphQL layer has no observability instrumentation.
No Prometheus metrics, internal events, error tracking, or structured logging exist in any
resolver, type, mutation, or subscription for this surface.

### Queries

| Field | Where exposed | What it returns |
| --- | --- | --- |
| `duoWorkflowWorkflows` | Root query and `ProjectType` | Session list filtered by `workflowId`, `projectPath`, `type`, `environment`, `statusGroup`, and others |

Key fields fetched by the executor on each poll cycle: `statusName`, `projectId`,
`project` (languages, URLs, context exclusion settings), `namespaceId`,
`namespace` (AI settings including `promptInjectionProtectionLevel`),
`agentPrivilegesNames`, `preApprovedAgentPrivilegesNames`, `mcpEnabled`,
`allowAgentToRequestUser`, `latestCheckpoint` (with `compressedCheckpoint`
available in GitLab 19.0), `archived`, `stalled`.

### Field resolvers

| Field | What it does |
| --- | --- |
| `toolCallApproved(toolName, toolCallArgs)` | Checks whether a specific tool call is approved for the session. Called on every tool invocation |
| `auditEvents` | Returns AI audit events for the session. Gated by `read_agent_artifacts` ability and `agent_artifacts_page` feature flag (GitLab 19.0+) |

### Mutations

| Mutation | What it does |
| --- | --- |
| `duoWorkflowsCreate` | Creates a new workflow session |
| `duoWorkflowsDeleteWorkflow` | Deletes a workflow session |
| `duoWorkflowsUpdateAgentPrivileges` | Updates agent privilege grants for a session |
| `duoWorkflowsUpdateToolCallApprovals` | Updates per-session tool call approval policy |

### Subscriptions

| Subscription | What it does |
| --- | --- |
| `duoWorkflowsWorkflowEventsUpdated` | Streams live checkpoint events to the workflow owner; restricted to the session owner (not compliance reviewers) |

## Error tracking (Sentry)

`Gitlab::ErrorTracking.track_exception` is called with workflow context in:

- `CreateWorkflowService`: workflow creation failures
- `DestroyWorkflowService`: workflow deletion failures
- `GenerateWorkflowTitleService`: title generation failures (`workflow_id` attached)
- `SummarizeWorkflowService`: summary generation failures (`workflow_id` attached)
- `UpdateToolCallApprovalsService`: tool call approval update failures (`workflow_id` attached)
- `Otel::CreateWorkflowService`: OpenTelemetry (OTel) workflow creation failures (`workflow_id` attached)
- `CodeReview::ReviewMergeRequestService`: code review start failures (`unit_primitive` attached)
- `CancelAssociatedPipelinesWorker`: pipeline cancellation failures

## Rate limiting

Both endpoints share the same limiter key.

| Endpoint | Limiter key | Threshold | Scope |
| --- | --- | --- | --- |
| `POST /api/v4/ai/duo_workflows/direct_access` | `duo_workflow_direct_access` | 50 req/min | per user |
| `GET /api/v4/ai/duo_workflows/list_tools` | `duo_workflow_direct_access` | 50 req/min | per user |

Violations return HTTP 429 with a `Retry-After` header.
No dedicated Prometheus counter tracks rate limit hits (see the gaps section above).

## Audit events

`IngestAuditEventsService` receives events from the GitLab Duo Workflow Service
by using gRPC, batches them, and enqueues `ProcessAuditEventsWorker`. The worker:

1. Writes to ClickHouse by using the Redis write buffer (preferred path).
1. Falls back to PostgreSQL bulk insert when ClickHouse is unavailable.
1. Streams each event to configured audit event destinations.
1. Logs each event to `Gitlab::AuditJsonLogger`.

A unique index on `(cloud_event_id, created_at)` guarantees idempotency.

## Key source files

| File | Role |
| --- | --- |
| `ee/app/workers/ai/duo_workflows/process_audit_events_worker.rb` | Only file with Prometheus counters |
| `ee/app/services/ai/duo_workflows/concerns/workload_metrics.rb` | `duo_workflow_workload_completed` internal event |
| `ee/app/services/ai/duo_workflows/concerns/workflow_event_tracking.rb` | Session and execution internal events |
| `ee/app/services/ai/duo_workflows/code_review/observability.rb` | Code review error tracking and conditional logging |
| `ee/app/workers/ai/duo_workflows/update_workflow_status_event_worker.rb` | Triggers workload metrics on CI pipeline completion |
| `ee/lib/api/ai/duo_workflows/workflows.rb` | Public API. Rate limiting and vulnerability workflow event tracking |
| `ee/lib/api/ai/duo_workflows/workflows_internal.rb` | Internal API consumed by GitLab Duo Workflow Service and Executor |
| `ee/lib/ee/gitlab/application_rate_limiter.rb` | `duo_workflow_direct_access` rate limit definition (50 req/min) |
| `ee/config/events/` | Internal event definitions (`agent_platform_session_*`, `duo_workflow_*`, `*_mcp_tool_call`) |

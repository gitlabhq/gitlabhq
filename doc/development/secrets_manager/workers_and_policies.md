---
stage: Security Platform
group: Secrets Manager Application
info: Any user with at least the Maintainer role can merge updates to this content. For details, see <https://docs.gitlab.com/development/development_processes/#development-guidelines-review>.
title: Secrets Manager workers and policies
ignore_in_report: true
---

Secrets Manager runs its background work as Sidekiq workers under `ee/app/workers/secrets_management/`.
Authorization runs in two layers.
Rails policies live under `ee/app/policies/secrets_management/`.
OpenBao access control lists (ACLs) are checked against the caller's JSON Web Token (JWT).
OpenBao also calls back into GitLab through an internal API to deliver audit log lines.

## Workers

| Worker | Purpose | Enqueued by |
|--------|---------|-------------|
| `ProvisionProjectSecretsManagerTaskWorker` | Provisions a project secrets manager in OpenBao | `ProjectSecretsManagers::InitializeService`, and the project maintenance tasks cron worker on retry |
| `ProvisionGroupSecretsManagerTaskWorker` | Provisions a group secrets manager in OpenBao | `GroupSecretsManagers::InitializeService`, and the group maintenance tasks cron worker on retry |
| `ProvisionProjectSecretsManagerWorker` | Legacy direct provision worker, superseded by the task worker above | No longer enqueued anywhere in the codebase |
| `ProvisionGroupSecretsManagerWorker` | Legacy direct provision worker, superseded by the task worker above | No longer enqueued anywhere in the codebase |
| `DeprovisionProjectSecretsManagerWorker` | Deprovisions a project secrets manager | `ProjectSecretsManagers::InitiateDeprovisionService`, and the project maintenance tasks cron worker on retry |
| `DeprovisionGroupSecretsManagerWorker` | Deprovisions a group secrets manager | `GroupSecretsManagers::InitiateDeprovisionService`, and the group maintenance tasks cron worker on retry |
| `ProjectSecretsManagerMaintenanceTasksCronWorker` | Retries stale project provision or deprovision maintenance tasks | Cron |
| `GroupSecretsManagerMaintenanceTasksCronWorker` | Retries stale group provision or deprovision maintenance tasks | Cron |
| `ProjectSecretsManagerReapOrphanTasksCronWorker` | Terminates project maintenance tasks that exhausted their retries | Cron |
| `GroupSecretsManagerReapOrphanTasksCronWorker` | Terminates group maintenance tasks that exhausted their retries | Cron |
| `ReconcileNamespaceSecretCountWorker` | Refreshes the cached secret count for one namespace | `ReconcileNamespaceSecretCountsCronWorker`, and services that change a namespace's secret count |
| `ReconcileNamespaceSecretCountsCronWorker` | Enqueues `ReconcileNamespaceSecretCountWorker` for every namespace with a secrets manager | Cron |
| `EmitSecretsStoredBillableEventWorker` | Emits the secrets-stored billing event for one root namespace | `EmitSecretsStoredBillableEventCronWorker` |
| `EmitSecretsStoredBillableEventCronWorker` | Enqueues `EmitSecretsStoredBillableEventWorker` for every root namespace with stored secrets | Cron |
| `SecretRotationReminderBatchWorker` | Deprecated, does nothing, replaced by the two workers below | None. It is no longer scheduled. |
| `ProjectSecretRotationReminderBatchWorker` | Sends rotation reminders for project secrets | Cron |
| `GroupSecretRotationReminderBatchWorker` | Sends rotation reminders for group secrets | Cron |
| `AuditLogWorker` | Processes one OpenBao audit log line into a GitLab audit event and a billing event | `API::Internal::SecretsManager` |

For the business meaning of the billing events, see [Secrets Manager fulfillment and entitlement](fulfillment.md).
For the destroy and transfer flows that create deprovision maintenance tasks, see [Secrets Manager states and side effects](states_and_side_effects.md).

All workers set `feature_category :secrets_management` and `idempotent!`.
The provision and deprovision workers also set `worker_has_external_dependencies!`, because they call OpenBao.

## Cron schedules

Cron entries live in `ee/config/schedule.yml`.

| Worker | Schedule |
|--------|----------|
| `ProjectSecretsManagerMaintenanceTasksCronWorker` | Every minute |
| `GroupSecretsManagerMaintenanceTasksCronWorker` | Every minute |
| `ProjectSecretsManagerReapOrphanTasksCronWorker` | Every 15 minutes |
| `GroupSecretsManagerReapOrphanTasksCronWorker` | Every 15 minutes |
| `ProjectSecretRotationReminderBatchWorker` | Every minute |
| `GroupSecretRotationReminderBatchWorker` | Every minute |
| `ReconcileNamespaceSecretCountsCronWorker` | Daily at 02:23 |
| `EmitSecretsStoredBillableEventCronWorker` | Daily at 04:30 |

## Maintenance task retry and reaper rules

`ProjectSecretsManagerMaintenanceTasksCronWorker` and `GroupSecretsManagerMaintenanceTasksCronWorker` both inherit from `SecretsManagement::BaseMaintenanceTasksCronWorker`.
Each run selects tasks that are `processable` (`last_processed_at` older than `STALE_THRESHOLD`) and `retryable` (`retry_count` under `MAX_RETRIES`).
It then re-enqueues the matching provision or deprovision worker per task:

| Constant | Value |
|----------|-------|
| `BATCH_SIZE` | 100 |
| `STALE_THRESHOLD` | Five minutes |
| `MAX_RETRIES` | 3 |

Each task is retried in isolation. A `StandardError` on one task is tracked and does not stop the rest of the batch.

A task that reaches `MAX_RETRIES` drops out of the `retryable` scope and is never retried again by the cron worker.
`ProjectSecretsManagerReapOrphanTasksCronWorker` and `GroupSecretsManagerReapOrphanTasksCronWorker`, both inheriting from `SecretsManagement::BaseReapOrphanTasksCronWorker`, are the safety net for these stuck rows.
They select tasks with `retry_count` at or above `MAX_RETRIES` and `last_processed_at` older than `GRACE_PERIOD` (30 minutes).
They then call the deprovision service directly, regardless of whether the task's `action` was `provision` or `deprovision`.
The deprovision service tears down whatever OpenBao state exists at the task's snapshot paths, deletes the secrets manager row if it still exists, and deletes the task.
After this pass the parent project or group has no secrets manager and no maintenance task, so the user can initialize again.

The `GRACE_PERIOD` is longer than both `STALE_THRESHOLD` and the provisioning and deprovisioning lease duration.
So the reaper never races a worker that is about to retry naturally, or a lease that is about to expire on its own.

## Rotation reminder workers

`SecretsManagement::ProjectSecretRotationReminderBatchWorker` and `SecretsManagement::GroupSecretRotationReminderBatchWorker` both inherit from `SecretsManagement::BaseSecretRotationReminderBatchWorker`.
Each run calls its service class (`ProjectSecretRotationBatchReminderService` or `GroupSecretRotationBatchReminderService`) in a loop.
The loop is bounded by a `MAX_RUNTIME` of 30 seconds, and stops after a batch returns fewer processed and skipped rows than the service's batch size.
`SecretsManagement::SecretRotationReminderBatchWorker` is deprecated. It does nothing and is no longer scheduled.
The class stays until removal so that jobs queued by older versions still run.

The rotation reminder cron also cleans up orphaned rotation information rows left behind when a secret update fails after the rotation information write.
These orphan rows are expected. They are not a problem to fix.

## Authorization policies

Policy classes live under `ee/app/policies/secrets_management/`.
Every one of them delegates entirely to the parent resource's policy instead of defining abilities itself:

| Policy | Delegates to |
|--------|--------------|
| `ProjectSecretsManagerPolicy` | The project's `ProjectPolicy`, through `@subject.project` |
| `GroupSecretsManagerPolicy` | The group's `GroupPolicy`, through `@subject.group` |
| `ProjectSecretPolicy` | The project's `ProjectPolicy`, through `@subject.project` |
| `GroupSecretPolicy` | The group's `GroupPolicy`, through `@subject.group` |
| `ProjectSecretsPermissionPolicy` | The permission's resource, through `@subject.resource` |
| `GroupSecretsPermissionPolicy` | The permission's resource, through `@subject.resource` |
| `NamespaceEnrollmentPolicy` | The enrollment's namespace, through `@subject.namespace` |

`EE::ProjectPolicy` and `EE::GroupPolicy` hold the actual ability rules.
Both follow the same shape:

- A condition checks whether Secrets Manager is available for the subject (`SecretsManagement::Availability.for_project?` or `.for_group?`). When it is not, abilities such as `admin_project_secrets_manager`, `read_project_secrets`, `create_project_secrets`, `update_project_secrets`, `delete_project_secrets`, and `create_secrets_manager_api_jwt` (project), or `provision_secrets_manager`, `read_secrets_manager`, `read_secrets_permission`, `update_secrets_permission`, and `delete_secrets_permission` (group), are all prevented.
- When entitlement awareness is active, further conditions call `SecretsManagement::Entitlement.for` and prevent reads, writes, or JWT issuance based on the entitlement state.
- When the top-level group is `trial_eligible` and the namespace is not in the beta cohort, conditions on every project and every group that is not the top-level group prevent reads and deletes on the entitlement-aware path, because only the top-level group can start a trial.
- On `EE::GroupPolicy`, a separate enrollment-allowed condition controls the enrollment and trial abilities (`create_secrets_manager_enrollment`, `delete_secrets_manager_enrollment`, `read_secrets_manager_enrollment`, `enable_secrets_manager_add_on`, `start_secrets_manager_trial`).

A Rails ability passing is not enough on its own.
OpenBao ACL policies are a second, independent layer: the caller's JWT must also carry the right OpenBao policy for the operation to succeed.
A user with the Rails ability but no matching OpenBao policy still gets a permission error from OpenBao.

## Internal API

`ee/lib/api/internal/secrets_manager.rb` exposes `POST /api/v4/internal/secrets_manager/audit_logs`.
OpenBao, not a user, calls this endpoint to deliver one audit log line per operation.

Request handling:

- The request body is capped at 1 megabyte.
- Authentication is a shared secret compared against the `Gitlab-Openbao-Auth-Token` header. The secret is read from a file at a path from `Gitlab.config.openbao.authentication_token_secret_file_path`.
That path is resolved with `Pathname#realpath` and checked against an allowlist of root paths (`Rails.root`, or `/etc/gitlab/` outside development and test), to block symlink-based path traversal.
- OpenBao emits two lines per operation, one `request` type and one `response` type. Only the `response` line carries the outcome, so `request` lines are dropped before any processing.
- Processing is asynchronous: the endpoint enqueues `SecretsManagement::AuditLogWorker` and returns `202 Accepted` without waiting on the database.

## Audit log processing

`SecretsManagement::AuditLog`, backed by `ActiveModel`, parses the raw JSON from OpenBao.
It maps each line to one of eight event types, based on the operation (`create`, `read`, `update`, `delete`) and whether the path matched a secret's data or metadata path, for both project and group scope:

```plaintext
secrets_manager_read_project_secret
secrets_manager_create_project_secret
secrets_manager_update_project_secret
secrets_manager_delete_project_secret
secrets_manager_read_group_secret
secrets_manager_create_group_secret
secrets_manager_update_group_secret
secrets_manager_delete_group_secret
```

A create and an update both write the secret's metadata path as `update` operations.
`AuditLog` logs a metadata write only when its `custom_metadata` carries `update_completed_at`, which only an update's final write sets. So a create logs only its create event, from the data path write, and an update logs once.
`ProjectSecret` and `GroupSecret` are not `ActiveRecord` models, so they cannot be audit targets themselves.
`AuditLog#log!` calls `Gitlab::Audit::Auditor.audit` to create the GitLab audit event instead, with the project or group as both scope and target.

Sidekiq can redeliver a job whose write already committed, and the audit tables have no natural-key protection against a duplicate insert.
So `SecretsManagement::AuditLogWorker` wraps this processing with two guards against duplicate processing, keyed on OpenBao's request ID and cached for six hours:

- One marker guards the audit event write itself.
- A second marker guards emitting the secrets-read billing event, because the local billing path has no event ID of its own to deduplicate on downstream.

## Internal event tracking

Secrets Manager tracks product usage through `Gitlab::InternalEventsTracking`, with event definitions under `ee/config/events/`.
Examples outside enrollment include `create_ci_secret`, `visit_project_secrets_manager`, `visit_group_secrets_manager`, `generate_id_token_for_secrets_manager_authentication`, `enable_ci_secrets_manager_for_project`, `enable_ci_secrets_manager_for_group`, and `disable_ci_secrets_manager_for_group`.
Entitlement denial telemetry lives in `SecretsManagement::Entitlement::DenialTelemetry`.
For enrollment and trial events, see [Secrets Manager enrollment](enrollment.md).

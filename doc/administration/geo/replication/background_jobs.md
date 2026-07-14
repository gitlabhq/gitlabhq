---
stage: Tenant Scale
group: Geo
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Geo background jobs
---

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Geo persists all sync and verification intent in registry tables in the Geo
tracking database, not in Sidekiq job arguments.
If a job is killed, the registry record retains its state and cron-based
schedulers re-enqueue the work. This design makes Geo fundamentally crash-safe.

## Registry sync states

Every replicable data type has a registry record on the secondary site that
tracks sync state:

| State | Description |
|-------|-------------|
| `pending` | Needs sync. Picked up by the sync scheduler cron. |
| `started` | Sync in progress. If the worker is killed, the record stays in this state. |
| `synced` | Successfully replicated. |
| `failed` | Sync failed. Has a `retry_at` timestamp for exponential backoff retry. |

If a sync job is killed, the registry stays in `started`.
`Geo::SyncTimeoutCronWorker`, which runs every 10 minutes, detects the sync job state and marks
the registry as `failed` with retry backoff.
The sync scheduler cron worker then re-enqueues the registry for sync.

## Recovery mechanisms

The following cron workers provide automatic recovery. Their schedules are defined in [`ee/config/schedule.yml`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/config/schedule.yml) and are configurable.

The cron job name matches the name shown in the **Cron** tab of the Sidekiq dashboard in the [**Admin** area](../../admin_area.md#background-jobs).

| Mechanism | Worker | Cron job name | Default schedule | Purpose |
|-----------|--------|---------------|------------------|---------|
| Sync timeout recovery | `Geo::SyncTimeoutCronWorker` | `geo_sync_timeout_cron_worker` | Every 10 min (secondary) | Marks registries stuck in `started` state as `failed` with retry backoff. |
| Blob sync scheduler | `Geo::RegistrySyncWorker` | `geo_registry_sync_worker` | Every 1 min (secondary) | Polls for `pending` and `failed` blob registries and enqueues `Geo::SyncWorker`. |
| Repository sync scheduler | `Geo::RepositoryRegistrySyncWorker` | `geo_repository_registry_sync_worker` | Every 1 min (secondary) | Polls for `pending` and `failed` repository registries and enqueues `Geo::SyncWorker`. |
| Registry consistency | `Geo::Secondary::RegistryConsistencyWorker` | `geo_secondary_registry_consistency_worker` | Every 1 min (secondary) | Creates missing registry records for untracked replicables. Detects orphaned registries. |
| Verification timeout | `Geo::VerificationTimeoutWorker` | Triggered by `geo_verification_cron_worker` | Every 1 min (primary and secondary) | Marks verification stuck in `verification_started` as `verification_failed`. |
| Verification scheduler | `Geo::VerificationCronWorker` | `geo_verification_cron_worker` | Every 1 min (primary and secondary) | Triggers verification batch, timeout, re-verification, and state backfill workers. |

## Queue safety reference

The following sections provide per-worker safety information for Geo Sidekiq queues.

### Cron workers

Cron workers are scheduled automatically and re-run on the next cron tick if
their queue is cleared.
All cron worker queues are safe to clear.

| Worker | What it does | Safe to clear queue | Negative consequences of clearing | Recovery mechanism |
|--------|-------------|:-------------------:|-----------------------------------|-------------------|
| `Geo::RegistrySyncWorker` | Polls for pending and failed blob registries. Enqueues `Geo::SyncWorker`. | Yes | Sync is delayed until the next cron tick. | Re-runs every 1 min. |
| `Geo::RepositoryRegistrySyncWorker` | Polls for pending and failed repository registries. Enqueues `Geo::SyncWorker`. | Yes | Sync is delayed until the next cron tick. | Re-runs every 1 min. |
| `Geo::SyncTimeoutCronWorker` | Finds registries stuck in `started` state. Marks them `failed` with retry backoff. | Yes | Registries stuck in `started` are not transitioned to `failed` until the next tick. Sync resumes after the next tick. | Re-runs every 10 min. |
| `Geo::Secondary::RegistryConsistencyWorker` | Scans all registry types. Creates missing registries. Detects orphaned registries and enqueues `Geo::DestroyWorker`. | Yes | Missing registries are not created and orphaned registries are not cleaned up until the next tick. | Re-runs every 1 min. |
| `Geo::VerificationCronWorker` | Triggers all verification sub-workers. | Yes | Verification is delayed until the next cron tick. | Re-runs every 1 min. |
| `Geo::VerificationTimeoutWorker` | Recovers records stuck in `verification_started`. | Yes | Records stuck in `verification_started` are not transitioned until the next tick. | Re-runs every 1 min. |
| `Geo::PruneEventLogWorker` | Deletes old event log entries that all secondaries have consumed (primary only). | Yes | The event log grows until the worker runs again. No data loss. | Re-runs every 5 min. |
| `Geo::MetricsUpdateWorker` | Computes node status, updates Prometheus gauges, sends status to primary. | Yes | Metrics become stale until the worker runs again. | Re-runs every 1 min. |
| `Geo::SidekiqCronConfigWorker` | Enables and disables cron jobs based on node type (primary or secondary). | Yes | Cron job configuration may be incorrect until the worker runs again. | Re-runs every 1 min. |

### Sync workers (secondary)

| Worker | What it does | Safe to clear queue | Negative consequences of clearing | Recovery mechanism |
|--------|-------------|:-------------------:|-----------------------------------|-------------------|
| `Geo::SyncWorker` | Downloads a single blob or fetches a single repository from the primary site. | Yes | Registries for in-flight jobs stay in `started`. Sync is delayed until recovery. | `SyncTimeoutCronWorker` transitions stuck registries to `failed`. Sync scheduler re-enqueues. |
| `Geo::ContainerRepositorySyncWorker` | Syncs a single container repository from the primary site. | Yes | Registry retains its state. Sync is delayed until recovery. | Sync scheduler re-enqueues. |
| `Geo::BulkRegistryResyncWorker` | Triggers bulk re-sync of a registry class. | Yes | Bulk re-sync does not start. Individual registries retain their state. | Caller re-enqueues. |

### Event workers (primary and secondary)

> [!warning]
> When you clear event worker queues, events in the queue might be lost.
> Lost events can cause data to be temporarily out of date on the secondary site.

| Worker | What it does | Safe to clear queue | Negative consequences of clearing | Recovery mechanism |
|--------|-------------|:-------------------:|-----------------------------------|-------------------|
| `Geo::EventWorker` | Processes Geo replication events (`created`, `updated`, `deleted`) on the secondary site. | Use caution. | Losing `updated` events can leave a resource out of date until re-verification or the next update event. Losing `deleted` events can leave orphaned files on the secondary site (wasted disk, no data loss). Losing `created` events has no lasting effect. Has 3 Sidekiq retries. | Even if all retries fail, the registry record exists and the sync scheduler re-enqueues. `RegistryConsistencyWorker` also detects orphaned registries. |
| `Geo::BatchEventCreateWorker` | Bulk-inserts Geo events on the primary site. | Use caution. | Events in the queue are lost if cleared. Secondary sites may not learn about changes until re-verification. | `RegistryConsistencyWorker` on the secondary site eventually detects missing registries (every 1 min). |
| `Geo::CreateRepositoryUpdatedEventWorker` | Creates a Geo event when a repository is updated on the primary site. | Use caution. | Same as `Geo::BatchEventCreateWorker`. | Same as `Geo::BatchEventCreateWorker`. |

### Verification workers (primary and secondary)

| Worker | What it does | Safe to clear queue | Negative consequences of clearing | Recovery mechanism |
|--------|-------------|:-------------------:|-----------------------------------|-------------------|
| `Geo::VerificationBatchWorker` | Checksums batches of records. | Yes | Verification is delayed. | Cron re-enqueues. `VerificationTimeoutWorker` catches stuck records. |
| `Geo::ReverificationBatchWorker` | Marks already-verified records for periodic re-verification. | Yes | Re-verification is delayed. | Cron re-enqueues. |
| `Geo::VerificationStateBackfillWorker` | Backfills verification state table for replicable types. | Yes | Backfill is delayed. Exclusive lease expires in 30 min. | Re-enqueues itself. |
| `Geo::BulkPrimaryVerificationWorker` | Triggers bulk verification of a model class on the primary site. | Yes | Bulk verification does not start. | Caller re-enqueues. |
| `Geo::BulkRegistryReverificationWorker` | Triggers bulk re-verification of a registry class on the secondary site. | Yes | Bulk re-verification does not start. | Caller re-enqueues. |

### Destroy workers (secondary)

> [!warning]
> When you clear the destroy worker queue,
> lost jobs can leave orphaned files or repositories on the secondary site.

| Worker | What it does | Safe to clear queue | Negative consequences of clearing | Recovery mechanism |
|--------|-------------|:-------------------:|-----------------------------------|-------------------|
| `Geo::DestroyWorker` | Deletes a replicated file or repository on the secondary site after deletion on the primary site. | Use caution. | Orphaned files or repositories remain on the secondary site, wasting disk space. No data loss. Has 3 Sidekiq retries. | `RegistryConsistencyWorker` detects orphaned registries and re-enqueues `DestroyWorker`. |

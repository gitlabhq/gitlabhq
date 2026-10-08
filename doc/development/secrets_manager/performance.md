---
stage: Security Platform
group: Secrets Manager Application
info: Any user with at least the Maintainer role can merge updates to this content. For details, see <https://docs.gitlab.com/development/development_processes/#development-guidelines-review>.
title: Secrets Manager performance
ignore_in_report: true
---

Secrets Manager code calls two remote services: OpenBao and CustomersDot.
Most performance problems come from adding calls to them on a hot path (code that runs very often, like on every request or every CI job), or from work that grows with the number of secrets.
Keep these costs in mind when you change Secrets Manager code.
For general advice, see [Merge request performance guidelines](../merge_request_concepts/performance.md).

## Hot paths

| Path | Secrets Manager work | Cost control |
|------|----------------------|--------------|
| CI job pickup, `EE::Ci::RegisterJobService#secrets_manager_access_denied?` | License, availability, and entitlement checks for builds that request `gitlab_secrets_manager` secrets | One-second HTTP timeout per CustomersDot call, one-minute shared cache. Fails open on errors. |
| Runner payload, `EE::Ci::BuildRunnerPresenter` | Availability and entitlement checks, secrets manager lookups, CI JWT minting | Checks memoized once per project and once per distinct group. Same one-minute cache. Fails closed. |
| Sidebar menu item, `ChecksNavReadCapability` | OpenBao capability lookup on every project or group page render for users who can read secrets | Three-second OpenBao timeout, 30-second cache per user and secrets manager |
| Secrets page, `Projects::SecretsController#check_read_capability!` | Same capability lookup | Same 30-second cache, no timeout |
| GraphQL secret list and count | OpenBao `LIST` on every request | None |

At job pickup, a CustomersDot error is logged and the build is scheduled.
The presenter then resolves the entitlement again with the default timeout, and raises `SecretsManagement::Entitlement::AccessDeniedError` when access is denied.
The register job service maps that error to the `secrets_manager_access_denied` failure reason.

The presenter builds the project server block once per build.
The group server block is built for each group secret, so each group secret mints a new CI JWT and tracks an internal event.

Runners read secret values directly from OpenBao.
Rails sees each read only through the audit log callback.

## OpenBao round trips

Every request authenticates inline, so OpenBao validates the JWT on each call.
For details, see [Secrets Manager OpenBao client and authentication](openbao_client.md).

| Operation | OpenBao calls | Notes |
|-----------|---------------|-------|
| Create | 7 | Count `LIST` (skipped when the limit is `0`), metadata read, value write, metadata write, CI policy read and write, final metadata write |
| Update, scope unchanged | 5 or 6 | Metadata read, metadata write, value write (only when a value is given), CI policy read and write, final metadata write |
| Update, environment or branch changed | 7 to 9 | Adds a full secret `LIST` and a policy delete or rewrite for the old policy |
| Delete | 4 or 5 | Metadata read, delete, full secret `LIST`, then a policy delete or a policy read and write |
| List | 1 | One `LIST` on the detailed metadata path, plus one database query when the rotation fields are selected |
| Read one secret | 1 | Plus up to two database queries for rotation records |
| Count | 1 | `LIST` of all keys. Limit checks pass `limit + 1` so OpenBao stops early. |
| Effective capabilities | 3 | Login, `sys/capabilities-self`, then token revoke |

The list is not paginated in OpenBao.
`ProjectSecrets::ListService` and `GroupSecrets::ListService` load every secret, and the GraphQL connection pages the array in memory.
The services that list secrets needing rotation load the full list with rotation records, then filter and sort it in Ruby.

`SecretsManagerClient` accepts a `timeout:` option, but the secret services do not set it.
Those calls use the `Net::HTTP` defaults of 60 seconds for open and read.
Only the capability lookup from the sidebar sets a timeout.

## CI policy refresh cost

`CiPolicies::ProjectSecretRefresher` and `CiPolicies::GroupSecretRefresher` run on every create, update, and delete.
For the mechanics, see [Secrets Manager services](services.md).

- Adding a secret to a policy reads the whole access control list (ACL) policy and writes it back. The policy holds two paths for each secret in that scope, so its size grows with the number of secrets that share it.
- An update rewrites the policy even when the environment and branch did not change.
- Removing a secret from a policy calls `count_secrets_for_policy`, which lists every secret in the secrets manager with metadata. Delete and scope changes therefore cost O(number of secrets).

## Exclusive leases

Secret create, update, and delete share one lease key per project or group.
So do permission update and delete, provisioning, and deprovisioning.
Each lease has a time limit, or TTL (time to live), shown in the table below.
`Helpers::ExclusiveLeaseHelper#with_exclusive_lease_for` uses `retries: 0`, so a second caller gets "Another secret operation in progress" right away.
Requests do not queue.
Under load, parallel writes to one project or group fail, and writes to different projects or groups do not block each other.

| Caller | Lease TTL |
|--------|-----------|
| Secret and permission writes | 30 seconds (`DEFAULT_LEASE_TIMEOUT`) |
| Provisioning | 120 seconds |
| Deprovisioning (`BaseDeprovisionService::LEASE_TIMEOUT`) | 120 seconds |

A write makes up to nine OpenBao calls with no client timeout.
A stalled OpenBao can keep a write running past the 30 second lease, and then a second write can start.

## Bulk paths

- Group transfer. `EE::Groups::TransferService#bulk_initiate_secrets_manager_deprovisions` walks the subtree with `each_batch` of `GROUP_QUERY_BATCH_SIZE` and `PROJECT_QUERY_BATCH_SIZE`, both 1000. Each batch runs one `delete_all` on `active` secrets managers through `bulk_initiate_for_groups` and `bulk_initiate_for_projects`. The database trigger inserts a task for each row. No Sidekiq job is enqueued, because the code runs inside the transfer transaction. Per-record service calls would run several queries and one enqueue for each descendant inside the request.
- Project transfer deprovisions one record.
- Project and group destroy rely on `ON DELETE CASCADE` and the trigger.
- Maintenance and reaper crons process tasks in batches and isolate errors per task. For the constants, see [Secrets Manager workers and policies](workers_and_policies.md).
- `ReconcileNamespaceSecretCountsCronWorker` enqueues one worker per secrets manager in batches of 500, spread over a random delay of up to one hour.
- `EmitSecretsStoredBillableEventCronWorker` uses `bulk_perform_async_with_contexts` in batches of 500 root namespaces.

## CustomersDot and entitlement

For states, caches, and fallback behavior, see [Secrets Manager fulfillment and entitlement](fulfillment.md).
The performance angle:

- One uncached resolution makes two sequential HTTP calls: the trial lookup, then the consumer resolve.
- `Gitlab::SubscriptionPortal::Client` caches each response for its `Cache-Control` max-age, or 120 seconds (`CDOT_CACHE_FALLBACK_TTL`) without one. A max-age of `0` is not cached.
- Job pickup and the runner payload check both pass `cache_ttl`, set to `JOB_PICKUP_CACHE_TTL` (one minute). Rails policies, mutations, and UI helpers resolve the entitlement with no cross-request cache of their own.
- Each live resolution also writes the last-known-good record to Redis.

| Caller | HTTP timeout per call |
|--------|-----------------------|
| Default `Entitlement.for` | Two seconds behind a feature flag, otherwise the `Gitlab::HTTP` default |
| Job pickup check | One second |
| `secrets_read` emitter | 0.25 seconds |
| `Entitlement.for!` in mutations | `Gitlab::HTTP` default |

`Net::HTTP` retries a read timeout once on `GET`, so a stalled call can take about twice its timeout.

## Counts and limits

| Count | Source | When |
|-------|--------|------|
| Limit check on create | OpenBao `LIST` with `limit + 1` | Every create |
| GraphQL secret count | OpenBao `LIST` | Every request |
| `NamespaceSecretCount` | Database row | Read only by the `secrets_stored` billing path |

`ReconcileNamespaceSecretCountWorker` refreshes `NamespaceSecretCount` with one OpenBao `LIST` and one insert or update.
It runs after each create and delete and from the daily cron.
It is deduplicated per namespace, including scheduled jobs, and defers when database health signals degrade.

## Audit logs and billable events

OpenBao waits for the response of `POST /internal/secrets_manager/audit_logs` before it answers its own request.
Behind a feature flag, the endpoint skips request-type lines and enqueues `AuditLogWorker`.
With the flag off, it writes the audit log and emits `secrets_read` inline.

- `AuditLogWorker` is low urgency, deduplicated on the raw payload, and defers when audit tables are unhealthy.
- Each processed read resolves the entitlement for billing metadata, so it can call CustomersDot.
- The endpoint rejects bodies of 1 MB or more.

## Rate limits

The refresh entitlement mutations are the only Secrets Manager endpoints with their own application rate limit: `secrets_manager_entitlement_refresh`, 10 per user per minute.
Each refresh skips the CustomersDot caches and makes two live CustomersDot calls.
No other Secrets Manager endpoint or mutation has its own rate limit.
The access token REST endpoint mints a JWT locally and makes no OpenBao call.

## Performance review checklist

1. Does the change add an OpenBao or CustomersDot call to CI job pickup, the runner payload, or the sidebar?
1. Does a new call on a latency-sensitive path set a timeout, and does it fail open or closed on purpose?
1. Does the change add a call or a database query inside a loop over secrets, projects, or groups?
1. Does a new write path add work that grows with the number of secrets, like a full `LIST` in the refresher?
1. Does a new write take the per-entity lease, and can it finish well inside the lease TTL?
1. Does a new entitlement caller on a hot path pass `cache_ttl`, and does the matching mutation clear the cache?
1. Does a bulk path use `each_batch` with a constant batch size and avoid per-record service calls inside a transaction?
1. Does a new count read the source that matches its purpose, OpenBao for limits or `NamespaceSecretCount` for billing?

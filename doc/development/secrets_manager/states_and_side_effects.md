---
stage: Security Platform
group: Secrets Manager Application
info: Any user with at least the Maintainer role can merge updates to this content. For details, see <https://docs.gitlab.com/development/development_processes/#development-guidelines-review>.
title: Secrets Manager states and side effects
ignore_in_report: true
---

Secrets Manager has several kinds of state that can all be true at the same time.
For example, a secrets manager can still be provisioning when the trial for its top-level group ends.
Most bugs come from a combination of two states that the code didn't handle, not from a single state check.

For the checklist to use when you write or review a change, see [Secrets Manager change guidelines](change_guidelines.md).

## States that can combine

- Secrets manager lifecycle. States are `provisioning`, `active`, and `deprovisioning`. The `activate` event moves a record to `active`. Deprovisioning deletes the secrets manager row instead of changing its state, and `effective_status` reports `deprovisioning` while a deprovision task is pending. Creating, reading, updating, and deleting secrets all require the secrets manager to be `active`. Until a secrets manager is `active`, its user permission check (`UserPermissions::EffectiveCapabilitiesService`) returns false for everything and caches nothing, because the default role policies may not exist yet.
- Secret status. Computed from timestamps, not stored as a column. Values are `COMPLETED`, `CREATE_IN_PROGRESS`, `CREATE_STALE`, `UPDATE_IN_PROGRESS`, and `UPDATE_STALE`, with a 30 second staleness threshold. A secret can be `CREATE_STALE` while its parent secrets manager is still `active`.
- Maintenance task. A unique index allows one task per project or group, across both the `provision` and `deprovision` actions. A cron worker picks up tasks from the `unprocessed`, `stale`, and `retryable` scopes. The task, not the secrets manager row, is the lasting signal that a deprovision is running.
- Enrollment. Controls whether Secrets Manager is available, separate from the lifecycle state. For details, see [Availability gates](_index.md#availability-gates). Removing enrollment does not deprovision anything. It only blocks new reads and writes.
- Entitlement. The trial, paid, or billing status from `SecretsManagement::Entitlement`. It controls initializing, writes, and CI reads, and it can lapse while a secrets manager is `active`. For states and rules, see [Secrets Manager fulfillment and entitlement](fulfillment.md).
- Provisioning. `InitializeService` creates the secrets manager row and a provision task in one transaction, and a task worker provisions OpenBao. Initializing is blocked while a deprovision task is pending. The legacy direct provision workers only drain old jobs. The Owner, Maintainer, and Developer roles have the `provision_secrets_manager` ability. Starting a trial or enabling the add-on also provisions the top-level group's secrets manager when the user has that ability.
- Exclusive lease. Create, read, update, and delete (CRUD) operations, provisioning, and deprovisioning share one lease key per project or group, so they block each other. The lease lasts 30 seconds for CRUD operations and 120 seconds for provisioning and deprovisioning. A second caller fails immediately instead of waiting.

## Side effects on state transitions

This table lists what must happen together with each change in this area.
The last column shows what goes wrong if you skip it.

| Transition | Required side effect | Risk if skipped |
|------------|----------------------|-----------------|
| Secret create, update, or delete | CI policy refresh | A pipeline gains or keeps access it should not have |
| Secret create | Write the value and initial metadata, refresh policies, then mark the metadata complete | If the refresh fails, the secret exists in OpenBao but stays unreadable by pipelines, which is intentional |
| Secret update | Write metadata with check-and-set, write the value, refresh policies, then mark the update complete. Projects and groups share this order. | A refresh before the user writes would change policies even when OpenBao denies the write |
| Project or group destroy | The foreign key cascade deletes the secrets manager row, and an `AFTER DELETE` trigger inserts a deprovision task from the row's own organization, root namespace, and entity IDs | Cleanup code that reads the live parent fails, because the parent is gone |
| Project transfer | `InitiateDeprovisionService` deletes the secrets manager row after the transfer, and the trigger inserts the task | The old OpenBao namespace is never cleaned up |
| Group transfer | Bulk delete of `active` secrets managers in the subtree, in batches | Per-record deletion at scale times out the transfer request |
| Deprovision worker success | Delete the task, then any remaining secrets manager row, in one transaction | A leftover deprovision task blocks initializing Secrets Manager again |
| Namespace teardown | Tolerate the `containing child namespaces` and `route entry not found` errors | The cleanup cron retries forever on a state that is actually fine |
| Maintenance task reaches its retry limit | Leave the task in place. The reap orphan tasks cron runs deprovision on tasks at the retry limit after 30 minutes. | None. Do not treat a stuck task as a leak on its own. |
| Secret update fails after rotation information is written | Leave the rotation information row in place. The rotation reminder cron removes orphan rows. | None. Do not treat an orphan rotation row as a leak on its own. |
| Enrollment change | Record an audit event | The change leaves no audit trail |
| Rotation information write | Use `upsert` with `unique_by`, never a plain create or save | A race between a metadata update and a rotation write raises a duplicate key error |

## Fulfillment combinations

Entitlement changes outside GitLab, on a trial or billing schedule, so it often changes while another state is still changing.

| Combination | What the code does | What to check |
|-------------|--------------------|---------------|
| Entitlement lapses while the secrets manager is `active` | Loose read-only. UI reads and secret deletes still work, and CI reads work only during `grace`. Writes, permission changes, and user-initiated deprovision are blocked. Nothing is deprovisioned, and secrets are kept. | A new write path must be blocked here too. Deleting the project or group still deprovisions, through the database trigger. |
| Entitlement lapses while provisioning | The provision task fails, retries three times, and then the reap orphan tasks cron deprovisions it. The row and any partial OpenBao state are removed. | After entitlement comes back, the user must initialize again. |
| Entitlement lapses while a deprovision task is pending | Deprovision runs anyway. The deprovision worker and the maintenance and reap crons do not check entitlement. | Keep entitlement checks out of these cleanup paths, or cleanup can get stuck. |
| Entitlement comes back after a lapse | An `active` secrets manager works again after the caches expire. No re-initialize is needed. | Mutations that change entitlement must clear the caches. A renewal made directly in CustomersDot clears nothing until the cache expires or a user runs the refresh entitlement mutation. |
| Enrolled but `trial_eligible` or `ineligible` | `trial_eligible` gives top-level group reads only. `ineligible` denies everything. | Subgroup and project access differs from the top-level group. |
| Opted out on GitLab.com but `paid` | Entitlement stays `paid`, but availability is false. Everything is denied, CI jobs are dropped, and `secrets_stored` is not emitted. | Do not treat `paid` as available. Check availability and entitlement separately. |
| Project or group transfer | Every `active` secrets manager in the moved subtree is deprovisioned, whatever the entitlement of either root. A new one must pass the destination root entitlement. | The secret count row keeps the old root namespace until reconcile runs. |
| Entitlement lapses while a pipeline runs | Checked per job at pickup. Running jobs are unaffected. Later jobs fail with `secrets_manager_access_denied` after the caches expire. | Job pickup fails open on lookup errors, and the runner payload check fails closed. |
| CustomersDot outage | The last-known-good answer is replayed for up to 24 hours if it allowed direct reads. Otherwise entitlement is `ineligible`. | A trial that expires during the outage keeps working until the window ends. |
| Billing events for a blocked or `ineligible` namespace | Events are still emitted, with the entitlement state as metadata. | Do not make billing events depend on entitlement. |
| Strict read-only database | Nothing is written, whatever the entitlement. | Loose and strict read-only need separate handling. |

## Project and group differences

Project and group secrets managers mostly work the same way.
The list below covers where they differ.

- Project secrets use a `branch` parameter, and group secrets use a `protected` parameter, with different validation and a different metadata key.
- Project secrets managers give default secret management permissions to the Owner, Maintainer, and Developer roles, and group secrets managers give them to the Owner role only. Developers get `read` and `create`, so they can add a secret but cannot change one that already exists. The project and group difference is a product decision.
- Destroy and project transfer are per-record, and group transfer is bulk.
- Project and group share the same secret update order, and both provision Common Expression Language (CEL) roles only. A change that adds a new difference needs a stated reason.

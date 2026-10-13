---
source_checksum: 79bbac20f5502e42
distilled_at_sha: f881cd88ec49e57cc6d320e2b57c56d80cb06564
---
<!-- Auto-generated from docs.gitlab.com by gitlab-ai-principles-distiller — do not edit manually -->

# Secrets Manager Principles

## Checklist

### Documentation

- Update the matching page under `doc/development/secrets_manager/` in the same merge request when a change alters behavior that the page describes.
- Fix a Secrets Manager documentation page that was already out of date, either in the same merge request or in a follow-up.

### Lifecycle and States

- Require the secrets manager to be `active` for secret create, read, update, and delete (CRUD) operations, including when a deprovision task is pending (`effective_status` reports `deprovisioning`).
- DO NOT grant or cache user permissions for a secrets manager that is not `active`; `UserPermissions::EffectiveCapabilitiesService` returns false for everything until then because default role policies may not exist yet.
- DO NOT assume secret status is stored; it is computed from timestamps (`COMPLETED`, `CREATE_IN_PROGRESS`, `CREATE_STALE`, `UPDATE_IN_PROGRESS`, `UPDATE_STALE`, with a 30 second staleness threshold). A secret can be `CREATE_STALE` while its secrets manager is `active`.
- DO NOT change the secrets manager `state` to deprovision it; deprovisioning deletes the row, and the pending maintenance task is the lasting signal.
- Block initializing a secrets manager while a deprovision task is pending.
- Create the secrets manager row and the provision task in one transaction (`InitializeService`); DO NOT add new direct provision workers (the legacy ones only drain old jobs).
- Handle combinations of states, not a single state check; evaluate lifecycle, secret status, maintenance task, enrollment, entitlement, and lease together.

### Exclusive Lease and Maintenance Tasks

- Take the per-entity exclusive lease (shared by CRUD, provisioning, and deprovisioning for one project or group) on every new write path, and fail immediately when it is held instead of proceeding or waiting.
- Account for the unique task index (one task per project or group across `provision` and `deprovision`); ensure a new task insert that does nothing is handled, and that workers only run for rows actually inserted.
- DO NOT treat a maintenance task stuck at its retry limit as a leak; the reap orphan tasks cron runs deprovision on it after 30 minutes. Leave the task in place.
- DO NOT treat an orphan rotation information row left by a failed secret update as a leak; the rotation reminder cron removes it.
- Write rotation information with `upsert` and `unique_by`, never a plain create or save, to avoid duplicate key errors when racing with a metadata update.
- Ensure bulk operations cannot race with per-record operations on the same entity.

### Side Effects on State Transitions

- Refresh CI policies after every secret create, update, or delete so pipelines never gain or keep access they should not have.
- Follow the secret create order: write the value and initial metadata, refresh policies, then mark the metadata complete. DO NOT treat an unreadable secret after a failed refresh as a bug; it is intentional.
- Follow the secret update order for both projects and groups: write metadata with check-and-set (`metadata_cas`), write the value, refresh policies, then mark the update complete. DO NOT refresh policies before the user write succeeds.
- Use `metadata_cas` correctly so a concurrent update is never overwritten.
- Use IDs stored on the secrets manager row or deprovision task in cleanup code; DO NOT read the live project or group, because the parent may already be gone (the foreign key cascade deletes the row, and an `AFTER DELETE` trigger inserts the deprovision task from the row's own organization, root namespace, and entity IDs).
- Delete the secrets manager row through `InitiateDeprovisionService` after a project transfer so the trigger inserts the deprovision task; bulk delete `active` secrets managers in batches for a group transfer instead of per-record deletion.
- Handle secrets managers that project or group transfer skips because they are still provisioning.
- Delete the task, then any remaining secrets manager row, in one transaction on deprovision worker success; a leftover deprovision task blocks initializing again.
- Tolerate the `containing child namespaces` and `route entry not found` errors during namespace teardown so the cleanup cron does not retry forever.
- Record an audit event (`Gitlab::Audit::Auditor.audit`) for every enrollment change and for any new auditable action; add the matching event type definition under `config/audit_events/types/`.

### Project and Group Parity

- Check whether a fix on the project side also needs the group side (or the reverse) before merging; consult the documented differences first.
- State a reason for any new difference between project and group secrets managers.
- Use the `branch` parameter for project secrets and the `protected` parameter for group secrets, each with its own validation and metadata key.
- Keep default permissions as documented: Owner, Maintainer, and Developer for projects (Developers get `read` and `create` only), and Owner only for groups.
- Provision Common Expression Language (CEL) roles only for both project and group secrets managers.

### Guards and Peer Consistency

- Include the same guards as the closest existing peer (concerns, policy rules, active namespace checks, feature checks, entitlement checks) unless the change explains why not.
- Pair every Rails policy change with the matching OpenBao ACL or CEL logic, and the reverse.
- DO NOT assume entitlement stays constant during a multi-step operation such as provisioning or a running pipeline.

### Enrollment

- Treat enrollment as tri-state (no row, row with `disabled_at` nil, row with `disabled_at` set); DO NOT model it as a boolean.
- Resolve namespaces through `root_ancestor` by using `NamespaceEnrollment` class query methods (`enrolled?`, `opted_out?`, `beta_enrolled?`, `add_on_requested?`); they work with a group, subgroup, or project.
- Enroll only top-level groups on GitLab.com (`namespace_id` is unique and always a top-level group); use instance-wide enrollment through `SecretsManagement::InstanceEnrollment` on GitLab Self-Managed.
- Write enrollment only through `NamespaceEnrollmentService` and `InstanceEnrollmentService`; DO NOT update enrollment columns directly. Pass `current_user:` for the audit trail.
- Set `disabled_at` on unenroll instead of deleting the namespace enrollment row, so stored secrets and add-on intent are kept.
- Return an error and create no audit event when calling `enroll` on an already-enrolled namespace or `unenroll` on one already opted out; `unenroll` on a never-enrolled group creates an opted-out row, records an audit event, and succeeds.
- Call `SecretsManagement::Entitlement::Resolver.clear_cache` on every enrollment write.
- Call `InstanceEnrollment.expire_settings` and expire `Gitlab::CurrentSettings` after any write to the instance enrollment columns; DO NOT cache instance enrollment at the process level through `Gitlab::CurrentSettings`.
- DO NOT expose instance enrollment through the REST application settings API; change it only through the dedicated GraphQL mutations.
- Use `revert_add_on_intent` to undo exactly what `enroll_with_add_on_intent` changed when a later step in the add-on flow fails, and emit `secrets_manager_namespace_unenroll` or `secrets_manager_instance_unenroll` for the rollback.
- Emit `secrets_manager_add_on_enable` through `audit_add_on_conversion` once billing confirms the add-on; use `Gitlab::Audit::InstanceScope` as both `scope` and `target` for instance-scoped events.

### Availability

- Route every availability check through `SecretsManagement::Availability` (`for_project?`, `for_group?`, `for_instance?`); DO NOT branch on `Gitlab.com?` in callers.
- DO NOT call `enabled_for_project?` or `enabled_for_group?` on an access path; they skip the license check and are only for use inside `for_project?` and `for_group?`.
- Preserve the paid top-level group exception on GitLab.com (root groups get access without an enrollment row), but let an explicit opt-out (`NamespaceEnrollment.opted_out?`) override it; every other case falls back to `enrolled?`.
- Ensure disabling availability takes effect in all three layers without extra code: Rails policies (`secrets_manager_enabled`, `group_secrets_manager_enabled`), view rendering (`SecretsManagement::EnrollmentHelper`), and the CI runner payload (`Ci::BuildRunnerPresenter` returns `{}` when unavailable).
- Use the `secrets_manager_available_for_*?` view helpers for project or subgroup availability checks in views; use the `*_available_and_active_for_*?` helpers when the record must also be `active` (they perform no ability check).
- DO NOT treat `paid` entitlement as available; check availability and entitlement separately (an opted-out `paid` GitLab.com namespace is denied, its CI jobs are dropped, and `secrets_stored` is not emitted).
- Hide the enrollment toggles entirely when enrollment is not allowed (`allow_secrets_manager_namespace_enrollment?`, `allow_secrets_manager_instance_enrollment?`) instead of showing them disabled.

### Enrollment Authorization and GraphQL

- Keep the enrollment abilities (`create_`, `delete_`, `read_secrets_manager_enrollment`) separate from the abilities used to consume Secrets Manager; grant them to the group Owner (namespace) or instance administrator (instance), define them under `config/authz/permissions/secrets_manager_enrollment/`, and grant them to the Owner role in `config/authz/roles/owner.yml`.
- Gate group enrollment abilities on `NamespaceEnrollment.enrollment_allowed?` in `EE::GroupPolicy` and instance abilities on `InstanceEnrollment.enrollment_allowed?` in `EE::GlobalPolicy`.
- Use `authorize_granular_token` in addition to `authorize` on enrollment GraphQL mutations that accept `namespace_path` (scoped to the group), and scope instance mutations and the instance query type to the instance boundary with an assignable permission.
- DO NOT add new GraphQL types to `config/authz/graphql/authorization_todo.txt`; it is closed to new entries.
- Resolve `namespaceSecretsManagerEnrollment` only for top-level group paths and only for enabled rows (return `null` for subgroups, projects, and opted-out groups).
- Restrict `NamespaceSecretsManagerEnroll` and `NamespaceSecretsManagerUnenroll` to GitLab.com; guard instance mutations with `can_admin_all_resources?` through `authorize!(:global)`.
- Reject namespace enrollment for archived or pending-deletion groups through `RequiresActiveNamespace`; DO NOT apply that check to unenroll.

### Entitlement

- Treat `SecretsManagement::Entitlement` as a computed value object (via `Entitlement::Resolver`) with no database row; require license, enrollment, and entitlement to all allow an action.
- Enforce the entitlement matrix: `trial`, `paid`, and `offline_paid` allow everything; `blocked` with `grace` allows UI reads, CI reads, and deletes only; `blocked` with any other reason allows UI reads and deletes only; `trial_eligible` allows top-level group reads and deletes only; `ineligible` denies everything.
- Block new write paths (create, update, permission changes, initialize, provision, user-initiated deprovision) when entitlement blocks writes, in the same places peers do: Rails policies (`EE::ProjectPolicy`, `EE::GroupPolicy`), `SecretsManagement::EntitlementGate#validate_entitlement` in initialize and provision services, the `EnforcesWriteEntitlement` concern on GraphQL mutations, and CI job pickup (`EE::Ci::RegisterJobService`, `EE::Ci::BuildRunnerPresenter`).
- DO NOT include `EnforcesWriteEntitlement` in secret delete mutations, and DO NOT block deletes unless entitlement also blocks reads.
- Handle loose read-only (entitlement `blocked`: reads and deletes work, writes do not) separately from strict read-only (read-only database: nothing is written).
- DO NOT deprovision or delete secrets when entitlement lapses or a trial ends; an `active` secrets manager stays `active` in loose read-only mode. Deleting the project or group still deprovisions through the database trigger.
- DO NOT call entitlement checks from the deprovision worker or the maintenance and reap cleanup crons; they must run regardless of entitlement.
- Expect a provision task to fail, retry three times, and be deprovisioned by the reap orphan tasks cron when entitlement lapses during provisioning; the user must initialize again.
- Deprovision every `active` secrets manager in the moved subtree on transfer, regardless of either root's entitlement; require a new secrets manager to pass the destination root entitlement.
- Clear the entitlement caches in any mutation that changes entitlement; a renewal made directly in CustomersDot clears nothing until the cache expires or the refresh entitlement mutation runs.
- Start trials only when a fresh CustomersDot lookup (skipping every cache) returns `trial_eligible`; return `trial_already_active` for a running trial and `ineligible` for any other state. Keep the trial active when provisioning fails afterward and return the error next to the entitlement.
- Require the `enable_secrets_manager_add_on` ability and the 10 calls per user per minute rate limit on `SecretsManagerRefreshEntitlement`; on failure return an error and keep the cached and last-known-good answers.
- Include a digest of the `Entitlement` field list in the CI job pickup cache key (`Rails.cache`, one minute) so adding a field changes the key safely during a rolling deploy.
- Cache only successful CustomersDot responses (never errors), for the `Cache-Control` max-age or 120 seconds without one.
- Replay the 24-hour last-known-good CustomersDot answer on an outage only when it allowed direct reads; otherwise fail closed to `ineligible`. DO NOT replay it on an explicit refresh.
- Check entitlement per job at pickup: running jobs are unaffected, later jobs fail with `secrets_manager_access_denied`; job pickup fails open on lookup errors, and the runner payload check fails closed.
- Resolve entitlement as `offline_paid` or `blocked` with `subscription_grace_period_expired` (no grace window) on offline instances, and as `ineligible` for Self-Managed trial licenses and instances with no license.
- Treat beta enrollment as granting no extra entitlement; the only difference is that a beta `trial_eligible` namespace can still see and delete secrets on subgroups and projects.

### Billing Events

- DO NOT make billing events (`secrets_stored`, `secrets_read`) depend on entitlement; emit them with the entitlement state and blocked reason as metadata, even for blocked or `ineligible` namespaces.
- DO NOT emit `secrets_stored` for opted-out GitLab.com namespaces or unenrolled GitLab Self-Managed instances.
- Keep secret counts current through `ReconcileNamespaceSecretCountWorker` after every secret create and delete, after deprovision, and from the daily cron; remove the count row when the secrets manager is missing or not `active`. Expect the count row to keep the old root namespace after a transfer until reconcile runs.

### Documentation Routing

- Consult the matching page under `doc/development/secrets_manager/` for the changed area: fulfillment (`entitlement`, `trial`, `add_on`, `billable`, `subscription_portal`, `secret_count`), enrollment (`enrollment`, `availability`), services, GraphQL, OpenBao client, workers and policies, performance, architecture, testing, or frontend.

## Authoritative sources

For the full picture, see:

- doc/development/secrets_manager/states_and_side_effects.md
- doc/development/secrets_manager/fulfillment.md
- doc/development/secrets_manager/enrollment.md
- doc/development/secrets_manager/change_guidelines.md


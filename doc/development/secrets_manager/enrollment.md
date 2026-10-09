---
stage: Security Platform
group: Secrets Manager Application
info: Any user with at least the Maintainer role can merge updates to this content. For details, see <https://docs.gitlab.com/development/development_processes/#development-guidelines-review>.
title: Secrets Manager enrollment
ignore_in_report: true
---

Enrollment is one of the two gates in [Availability gates](_index.md#availability-gates).
It answers one question: has this namespace or instance turned Secrets Manager on.
The other gate is the `native_secrets_management` license.
Entitlement, which decides what an enrolled namespace can do based on trial and billing state, is a separate topic.
See [Secrets Manager fulfillment and entitlement](fulfillment.md).

## Namespace enrollment on GitLab.com

Enrollment on GitLab.com is per top-level group.
The model is `SecretsManagement::NamespaceEnrollment` at `ee/app/models/secrets_management/namespace_enrollment.rb`, backed by the `secrets_manager_namespace_enrollments` table.

| Column | Purpose |
|--------|---------|
| `namespace_id` | Unique. Always a top-level group. |
| `beta` | Set at enroll time. See [Beta program](fulfillment.md#beta-program). |
| `disabled_at` | `nil` means enrolled. A timestamp marks an explicit opt-out. |
| `add_on_requested_at` | Set when the group buys the paid add-on without a trial. See [Trials and add-ons](fulfillment.md#trials-and-add-ons). |

Enrollment is tri-state, not a plain boolean:

- No row. The group never enrolled.
- A row with `disabled_at` set to `nil`. The group is enrolled.
- A row with `disabled_at` set. The group explicitly opted out.

`NamespaceEnrollment.enrolled?(namespace)` and the other class query methods (`opted_out?`, `beta_enrolled?`, `add_on_requested?`) all resolve the namespace to its `root_ancestor` first.
This means they work the same whether you call them with the top-level group, or with a project or subgroup underneath it.

## Instance enrollment on GitLab Self-Managed

Enrollment on GitLab Self-Managed is instance-wide, not per namespace.
It is a set of columns on `application_settings`, read through `SecretsManagement::InstanceEnrollment` at `ee/app/models/secrets_management/instance_enrollment.rb`:

| Column | Purpose |
|--------|---------|
| `secrets_manager_instance_enrolled` | Defaults to `false`. `true` means the instance is enrolled. |
| `secrets_manager_instance_beta_enrolled` | Set at enroll time. Same meaning as the namespace `beta` column. |
| `secrets_manager_instance_add_on_requested_at` | Set when the instance buys the paid add-on without a trial. |

`InstanceEnrollment.settings` reads only these columns and caches them in `Gitlab::SafeRequestStore` for the current request.
Caching at the process level, through `Gitlab::CurrentSettings`, is too coarse for a check that affects CI job pickup.
Any write to these columns must call `InstanceEnrollment.expire_settings` and expire `Gitlab::CurrentSettings` so the next read in the same request sees the change.
The setting is not exposed through the REST application settings API.
The dedicated GraphQL mutations described below are the only way to change it.

## Services

Two services own all enrollment writes.
Do not update the enrollment columns directly.

| Service | File |
|---------|------|
| `SecretsManagement::NamespaceEnrollmentService` | `ee/app/services/secrets_management/namespace_enrollment_service.rb` |
| `SecretsManagement::InstanceEnrollmentService` | `ee/app/services/secrets_management/instance_enrollment_service.rb` |

Both take `current_user:` for the audit trail and expose the same four operations:

| Method | What it does |
|--------|---------------|
| `enroll` | Creates or re-enables the enrollment record. Fails if enrollment is not allowed, or if already enrolled. |
| `unenroll` | Opts the namespace or instance out. |
| `enroll_with_add_on_intent` | Enrolls if needed, then stamps `add_on_requested_at`. Used by the paid add-on purchase flow. |
| `revert_add_on_intent` | Undoes exactly what `enroll_with_add_on_intent` changed, used when a later step in that flow fails. |

`NamespaceEnrollmentService#unenroll` sets `disabled_at` instead of deleting the row.
Stored secrets are kept, and re-enrolling resumes without losing the paid add-on intent.

`InstanceEnrollmentService#unenroll` always clears `secrets_manager_instance_enrolled` rather than deleting anything, because instance enrollment is a set of columns, not a row.

Calling `enroll` on an already-enrolled namespace, or `unenroll` on one that already opted out, returns an error response and creates no audit event.
`unenroll` on a group that never enrolled creates an opted-out row, records an audit event, and succeeds.

Each service also clears the entitlement resolver cache on every write, through `SecretsManagement::Entitlement::Resolver.clear_cache`.
Without this, CI job pickup could keep granting or denying secrets access for the length of the entitlement cache time to live (TTL) after an enrollment change.

## Availability and enrollment

All availability checks go through `SecretsManagement::Availability` at `ee/lib/secrets_management/availability.rb`.
It is also the place that decides whether to consult namespace enrollment or instance enrollment, so callers never need to branch on `Gitlab.com?` themselves.

| Method | Checks |
|--------|--------|
| `for_project?(project)` | License and `enabled_for_project?`. |
| `for_group?(group)` | License and `enabled_for_group?`. |
| `for_instance?` | License and `InstanceEnrollment.enrolled?`. |
| `enabled_for_project?(project)` | Enrollment. No license check. Only called from `for_project?`, so never call it on an access path. |
| `enabled_for_group?(group)` | Enrollment, with the paid top-level group exception below. No license check. Only called from `for_group?`, so never call it on an access path. |

`enabled_for_group?` and `for_group?` route like this:

- On GitLab.com, `NamespaceEnrollment.enrolled?(resource)`.
- On GitLab Self-Managed, `InstanceEnrollment.enrolled?`.

### Paid top-level group exception on GitLab.com

A top-level group on GitLab.com does not need an enrollment row to get access.
`enabled_for_group?` grants it automatically, so the trial call-to-action stays reachable before the group ever enrolls.
An explicit opt-out still overrides this grant.
If `NamespaceEnrollment.opted_out?(group)` is true, the group is unavailable even though the paid-experience grant would otherwise allow it.
This exception only applies to root groups on GitLab.com.
Every other case, including GitLab Self-Managed and non-root groups, falls back to the plain `enrolled?` check.

## Where availability is enforced

Availability and enrollment are checked in three separate layers.
Disabling any one of them, for example by removing an enrollment record, must take effect in all three without any extra code:

| Layer | Where |
|-------|-------|
| Rails policies | The `secrets_manager_enabled` (project) and `group_secrets_manager_enabled` (group) policy conditions call `Availability.for_project?` and `Availability.for_group?`. |
| View rendering | `SecretsManagement::EnrollmentHelper` at `ee/app/helpers/secrets_management/enrollment_helper.rb`, mixed into `EE::ApplicationHelper` for views, and included explicitly in `Projects::SecretsController` and `Groups::SecretsController` so `before_action` callbacks can call it too. |
| CI runner payload | `Ci::BuildRunnerPresenter` (`ee/app/presenters/ee/ci/build_runner_presenter.rb`). `project_secrets_manager_payload` and `group_secrets_manager_payload` return `{}` when `Availability.for_project?` or `Availability.for_group?` is false, so jobs picked up after a namespace is unenrolled get no secrets. Jobs already running keep theirs. |

The helper methods:

| Method | Purpose |
|--------|---------|
| `allow_secrets_manager_namespace_enrollment?(namespace)` | Should the group settings page show the namespace enrollment toggle. |
| `allow_secrets_manager_instance_enrollment?` | Should the admin settings page show the instance enrollment toggle. |
| `secrets_manager_available_for_group?(group)` | `Availability.for_group?` plus the `read_secrets_manager` ability. |
| `secrets_manager_available_for_project?(project)` | `Availability.for_project?` plus the `read_project_secrets_manager` ability. |
| `secrets_manager_available_and_active_for_group?(group)` | `Availability.for_group?` plus the `GroupSecretsManager` record is `active?`. No ability check. |
| `secrets_manager_available_and_active_for_project?(project)` | `Availability.for_project?` plus the `ProjectSecretsManager` record is `active?`. No ability check. |

## Authorization

The ability to change enrollment itself is separate from the ability to use Secrets Manager.
This lets the enrollment toggle work even before a namespace is enrolled.

| Ability | Who |
|---------|-----|
| `create_secrets_manager_enrollment` | Group Owner (namespace), instance administrator (instance). |
| `delete_secrets_manager_enrollment` | Group Owner (namespace), instance administrator (instance). |
| `read_secrets_manager_enrollment` | Group Owner (namespace), instance administrator (instance). |

Permission definitions live at `config/authz/permissions/secrets_manager_enrollment/{create,delete,read}.yml`, and are granted to the Owner role in `config/authz/roles/owner.yml`.

For the group case, `EE::GroupPolicy` only grants all three abilities when `NamespaceEnrollment.enrollment_allowed?(@subject)` is true. That method checks the license and whether the group is a licensed GitLab.com top-level group.
For the instance case, `EE::GlobalPolicy` enables all three abilities for an `admin` when `InstanceEnrollment.enrollment_allowed?` is true.

`SecretsManagement::NamespaceEnrollmentPolicy` (`ee/app/policies/secrets_management/namespace_enrollment_policy.rb`) delegates straight to the group policy of the enrollment's namespace.
GraphQL mutations that accept a `namespace_path` use `authorize_granular_token` in addition to the Rails `authorize` declaration, scoped to that group.
Instance mutations use `authorize_granular_token` scoped to the instance boundary.

## Audit events

Every `enroll` and `unenroll` call creates an audit event through `Gitlab::Audit::Auditor.audit`.

| Event | Scope | Emitted by |
|-------|-------|------------|
| `secrets_manager_namespace_enroll` | Group | `NamespaceEnrollmentService#enroll` |
| `secrets_manager_namespace_unenroll` | Group | `NamespaceEnrollmentService#unenroll`, and to roll back a failed add-on stamp |
| `secrets_manager_instance_enroll` | Instance | `InstanceEnrollmentService#enroll` |
| `secrets_manager_instance_unenroll` | Instance | `InstanceEnrollmentService#unenroll`, and to roll back a failed add-on stamp |
| `secrets_manager_add_on_enable` | Group or instance | `audit_add_on_conversion` on either service, called once billing confirms the add-on |

Instance-scoped events use `Gitlab::Audit::InstanceScope` as both `scope` and `target`.
Type definitions live at `config/audit_events/types/secrets_manager_*.yml`.

## GraphQL

### Queries

| Field | Type | Resolver |
|-------|------|----------|
| `namespaceSecretsManagerEnrollment` | `SecretsManagerEnrollment` (`namespace`, `beta`) | `NamespaceEnrollmentResolver` |
| `instanceSecretsManagerEnrollment` | `SecretsManagerInstanceEnrollment` (`enrolled`, `beta`) | `InstanceEnrollmentResolver` |

`NamespaceEnrollmentResolver` only resolves for a top-level group path.
A subgroup or project path returns `null`.
It also only returns enabled rows, so an opted-out group resolves to `null` rather than a record with a disabled state.
This keeps older frontend code, which treats any record as "enrolled", from showing a false positive.
For an availability check on a project or a subgroup, use the `secrets_manager_available_for_*?` view helper instead.

The instance query type declares `authorize_granular_token` with an instance boundary, backed by the assignable permission at `config/authz/permission_groups/assignable_permissions/secrets_management/secrets_manager_enrollment/read.yml`.

The namespace enrollment type and the four enrollment mutations predate that requirement and are listed in `config/authz/graphql/authorization_todo.txt`.
New GraphQL types cannot be added to that file.

### Mutations

| Mutation | Guard |
|----------|-------|
| `NamespaceSecretsManagerEnroll` | `create_secrets_manager_enrollment`, and only runs on GitLab.com. |
| `NamespaceSecretsManagerUnenroll` | `delete_secrets_manager_enrollment`, and only runs on GitLab.com. |
| `InstanceSecretsManagerEnroll` | `can_admin_all_resources?` through `authorize!(:global)`. |
| `InstanceSecretsManagerUnenroll` | `can_admin_all_resources?` through `authorize!(:global)`. |

Files are under `ee/app/graphql/mutations/secrets_management/enrollment/`, registered in `ee/app/graphql/ee/types/mutation_type.rb`.
`NamespaceEnroll` also rejects the mutation if the target group is archived or pending deletion, through the `RequiresActiveNamespace` concern.
`NamespaceUnenroll` does not apply that check, so a group can still be unenrolled while archived or pending deletion.

## UI surfaces

- The namespace enrollment toggle is part of the group settings page, in `ee/app/assets/javascripts/pages/projects/shared/permissions/secrets_manager/`.
- The instance enrollment toggle is on the admin application settings page, rendered from `ee/app/views/admin/application_settings/_secrets_manager_instance_enrollment.html.haml`, backed by the Vue component at `ee/app/assets/javascripts/admin/application_settings/general/secrets_manager_instance_enrollment/`.

Both toggles are controlled by `allow_secrets_manager_namespace_enrollment?` and `allow_secrets_manager_instance_enrollment?` from the view helper described above, so they are hidden entirely when enrollment is not allowed rather than shown disabled.

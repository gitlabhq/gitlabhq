---
stage: Security Platform
group: Secrets Manager Application
info: Any user with at least the Maintainer role can merge updates to this content. For details, see <https://docs.gitlab.com/development/development_processes/#development-guidelines-review>.
title: Secrets Manager services
ignore_in_report: true
---

Secrets Manager business logic lives in plain Ruby service objects under `ee/app/services/secrets_management/`.
Shared behavior lives in modules under `ee/app/services/concerns/secrets_management/` and two smaller helper locations.
The sections below cover the base service classes, the shared concerns, the secret CRUD flow, CI policy refresh, the count and rotation list services, and error handling.

## Base service classes

| Class | File | Provides |
|---|---|---|
| `SecretsManagement::ProjectBaseService` | `ee/app/services/secrets_management/project_base_service.rb` | `base_secrets_manager_client`, `namespace_secrets_manager_client`, `project_secrets_manager_client`, `user_client` |
| `SecretsManagement::GroupBaseService` | `ee/app/services/secrets_management/group_base_service.rb` | Same client methods, scoped to `group_secrets_manager_client` instead of a project client |
| `SecretsManagement::BaseDeprovisionService` | `ee/app/services/secrets_management/base_deprovision_service.rb` | The shared async deprovision flow. See [Secrets Manager states and side effects](states_and_side_effects.md) |

Both base services include `Gitlab::Utils::StrongMemoize`, `Helpers::ExclusiveLeaseHelper`, `Helpers::ErrorResponseHelper`, and `EntitlementGate`.
Both also take the project or group in their constructor.
Each client method builds a JWT (`ProjectSecretsManagerJwt`, `GroupSecretsManagerJwt`, or a user JWT) and wraps it in a `SecretsManagerClient`.
`user_client` authenticates with a user JWT and CEL (Common Expression Language) auth. It is the client that secret CRUD services use.
Create is the one exception: it writes metadata with the application client, so a `create` grant can finish a creation without `update`.
For entitlement checks, billing states, and the `secrets_manager_paid_experience` behavior, see [Secrets Manager fulfillment](fulfillment.md).

## Service concerns

Shared logic lives in `ee/app/services/concerns/secrets_management/`.

| Concern | File | Used by |
|---|---|---|
| `EntitlementGate` | `entitlement_gate.rb` | Both base services, to reject writes when entitlement blocks them |
| `InitializeServiceHelpers` | `initialize_service_helpers.rb` | The project and group secrets manager initialize services |
| `InitiateDeprovisionServiceHelpers` | `initiate_deprovision_service_helpers.rb` | The project and group initiate deprovision services |
| `Secrets::CreateServiceHelpers` | `secrets/create_service_helpers.rb` | Secret create services |
| `Secrets::UpdateServiceHelpers` | `secrets/update_service_helpers.rb` | Secret update services |
| `Secrets::DeleteServiceHelpers` | `secrets/delete_service_helpers.rb` | Secret delete services |
| `Secrets::ListNeedingRotationServiceHelpers` | `secrets/list_needing_rotation_service_helpers.rb` | The rotation list services |
| `ProjectSecrets::SecretRefresherHelper` | `project_secrets/secret_refresher_helper.rb` | Project secret create, update, and delete services |
| `SecretsManagers::DefaultRolePoliciesHelper` | `secrets_managers/default_role_policies_helper.rb` | The provision services, to create the default role ACL policies: Owner, Maintainer, and Developer for projects, Owner only for groups |
| `SecretsPermissions::UpdateServiceHelpers` | `secrets_permissions/update_service_helpers.rb` | Permissions update services |
| `SecretsPermissions::DeleteServiceHelpers` | `secrets_permissions/delete_service_helpers.rb` | Permissions delete services |
| `SecretsPermissions::ListServiceHelpers` | `secrets_permissions/list_service_helpers.rb` | Permissions list services |

The group refresher helper is not under this directory.
It lives at `ee/app/services/secrets_management/group_secrets/secret_refresher_helper.rb`, next to the group secret services themselves.
When you add a group-specific helper, follow this existing location instead of assuming everything goes under `concerns/`.

Two smaller locations hold non-concern helpers:

- `ee/app/services/secrets_management/helpers/`. Small modules mixed into the base services: `ExclusiveLeaseHelper` (`with_exclusive_lease_for`) and `ErrorResponseHelper` (`secrets_manager_inactive_response`, `deprovision_in_progress_response`).
- `ee/app/services/secrets_management/concerns/secrets_count_service.rb`. A single concern, `SecretsCountService`, used only by the count services below.

### Abstract methods each concern expects

Some methods are enforced with `raise NotImplementedError` in the concern.
Others are called directly and must be defined somewhere in the including class, without an explicit guard.
Both are listed here because both are required for the service to work.

`EntitlementGate` expects one method, `entitlement_root_namespace`, returning the namespace whose entitlement state gates the write.

`InitializeServiceHelpers` and `InitiateDeprovisionServiceHelpers` back the provision and deprovision services.
For the provision and deprovision flow they drive, see [Side effects on state transitions](states_and_side_effects.md#side-effects-on-state-transitions).

`Secrets::CreateServiceHelpers` expects:

| Method | Purpose |
|---|---|
| `secrets_manager` | The active secrets manager, usually `delegate :secrets_manager, to: :project` (or `:group`) |
| `read_secret(secret)` | Check whether the secret already exists, by calling `ReadMetadataService` |
| `secrets_count_service` | Return the count service instance used for limit checking |
| `refresh_secret_ci_policies(secret)` | Refresh OpenBao ACL policies after creation |
| `user_client` | From the base service |

`Secrets::UpdateServiceHelpers` expects:

| Method | Purpose |
|---|---|
| `secrets_manager` | Active secrets manager |
| `user_client` | From the base service |
| `refresh_policies_after_update(secret)` | Refresh OpenBao ACL policies after the metadata and value are written. Optional, only called if the including service defines it |
| `error_response(secret)` | Build a `ServiceResponse.error` from a secret's validation errors |

`Secrets::DeleteServiceHelpers` expects:

| Method | Purpose |
|---|---|
| `secrets_manager` | Active secrets manager |
| `user_client` | From the base service |
| `read_secret(name)` | Read the secret before deleting it |
| `refresh_secret_ci_policies(secret, delete_operation: true)` | Remove the secret from its policy |

`SecretsManagers::DefaultRolePoliciesHelper` expects `secrets_manager`, `client` (an OpenBao client scoped to the secrets manager's namespace), `permission_class`, and `default_roles` (access levels to grant a default policy to, a subset of `ROLE_ACTIONS` keys).

`SecretsPermissions::UpdateServiceHelpers`, `DeleteServiceHelpers`, and `ListServiceHelpers` each expect `resource`, `client`, and `permission_class` from their including service. See [Permissions services](#permissions-services).

## Secret CRUD services

Each scope (`project_secrets/`, `group_secrets/`) has its own create, update, delete, list, and read metadata service.
They share the concerns above, so the logic in this section is the same for both scopes unless noted.

### Create

File: `ee/app/services/secrets_management/project_secrets/create_service.rb` (group equivalent under `group_secrets/`).

1. Acquires the exclusive lease for the project or group.
1. Builds the secret model (`ProjectSecret` or `GroupSecret`) and, if `rotation_interval_days` is given, a rotation information record.
1. Returns early if the secrets manager is not active, or if the secrets count limit is exceeded.
1. Validates the secret model. Checks whether the secret already exists by calling `ReadMetadataService`.
1. Validates the secret value size (maximum 10,000 bytes, `Secrets::CreateServiceHelpers::MAX_SECRET_SIZE`).
1. Upserts the rotation information record before any OpenBao write. This way, if the OpenBao write fails later, it leaves an orphan row that the rotation reminder cron cleans up, instead of a secret with no rotation tracking.
1. `start_secret_creation!`. Writes the value with `cas: 0`, then writes metadata with `metadata_cas: 0`.
1. `refresh_secret_ci_policies`. Updates the OpenBao ACL policy for pipeline read access.
1. `complete_secret_creation!`. Sets `create_completed_at` and writes metadata again with `metadata_cas: 1`.
1. Sets `secret.metadata_version = 2` in memory, so the GraphQL response and the next update call use the correct version.
1. Enqueues a namespace secret count refresh.

The value and metadata writes happen before the policy refresh by design: if policy creation fails, the secret exists in OpenBao but no pipeline can read it yet.
A retry then finds the secret already exists and returns "Secret already exists." The stale, incomplete secret needs manual or maintenance-job cleanup.

### Update

File: `ee/app/services/secrets_management/project_secrets/update_service.rb` (group equivalent under `group_secrets/`).

1. Acquires the exclusive lease.
1. Reads the current secret through `ReadMetadataService`.
1. Applies the given attribute changes and validates `valid_for_update?`.
1. Builds or upserts rotation information if `rotation_interval_days` changed.
1. Returns early if the secrets manager is not active.
1. Writes metadata first, with `metadata_cas` for optimistic locking. This runs before the value write so a CAS mismatch is caught before any value write happens.
1. Writes the value, if one was given.
1. Calls `refresh_policies_after_update`, after the value write. Both the project and the group update service now implement this same method name and run it after the writes, not before.
1. Writes completion metadata (`update_completed_at`) with an incremented `metadata_cas`.

If the metadata write raises `SecretsManagerClient::ApiError` with a check-and-set mismatch, `Secrets::UpdateServiceHelpers` catches it and returns "This secret has been modified recently. Please refresh the page and try again."

### Delete

File: `ee/app/services/secrets_management/project_secrets/delete_service.rb` (group equivalent under `group_secrets/`).

1. Acquires the exclusive lease for the resource.
1. Returns early if the secrets manager is not active.
1. Reads the current secret through `read_secret`. Returns the read error if the secret does not exist.
1. Deletes the value and metadata from OpenBao (`delete_kv_secret`).
1. Calls `refresh_secret_ci_policies(secret, delete_operation: true)` to remove the secret from its policy.
1. Enqueues a namespace secret count refresh.

### List

File: `ee/app/services/secrets_management/project_secrets/list_service.rb` (group equivalent under `group_secrets/`).

- Returns early if the secrets manager is not active.
- Calls `user_client.list_secrets` against the detailed metadata endpoint.
- Builds one secret model per entry from the OpenBao response.
- Accepts `include_rotation_info:` (default `true`). When set, batch-loads the referenced `ProjectSecretRotationInfo` or `GroupSecretRotationInfo` records by ID in a single query, instead of one query per secret.

### Read metadata

File: `ee/app/services/secrets_management/project_secrets/read_metadata_service.rb` (group equivalent under `group_secrets/`).

- Validates the secret name against `/\A[a-zA-Z0-9_]+\z/` before calling OpenBao.
- Returns `ServiceResponse.error(reason: :not_found)` if OpenBao has no metadata at that path.
- With `include_rotation_info: true` (the default), looks up rotation information for the current `metadata_version`, and falls back to `metadata_version - 1` if not found. This covers the race between the metadata write and the rotation information upsert landing.

## CI policy refresh

Creating, updating, or deleting a secret also updates the CI policies, so pipelines can read the right secrets.
File: `ee/app/services/secrets_management/ci_policies/base_secret_refresher.rb`, with `ProjectSecretRefresher` and `GroupSecretRefresher` subclasses in the same directory.

Create, update, and delete all call `refresh_ci_policies_for(secret, delete_operation:)` through the scope's refresher helper.
The refresher works out which policy the secret should be removed from and which policy it should be added to:

- Delete: remove from the current policy only.
- Update where the scoping attributes changed (project: `environment` or `branch`, group: `environment` or `protected`): remove from the old policy, add to the new one.
- Create, or update with no scoping change: add to the current policy only.

When a secret is removed from a policy, the refresher counts how many other secrets still resolve to that policy name by scanning `list_secrets`.
If the count is zero, it deletes the policy. Otherwise, it just removes that secret's read capability.

Policy names are computed by the secrets manager model (`ci_policy_name` for projects, `ci_policy_name_for_environment` for groups).
For the naming scheme and how ACL policies and capabilities are structured, see [Secrets Manager OpenBao client](openbao_client.md).

## Exclusive leases

Create, update, and delete acquire an exclusive lease through `Helpers::ExclusiveLeaseHelper#with_exclusive_lease_for`, keyed to the project or group.
A second operation on the same project or group fails immediately with "Another secret operation in progress" instead of waiting.
Provision and deprovision share this same lease. For the lease rules, see [States that can combine](states_and_side_effects.md#states-that-can-combine).

## Permissions services

Permissions services control who can read, write, or delete a secret.
Files: `ee/app/services/secrets_management/project_secrets_permissions/` and `group_secrets_permissions/`.
Concerns: `ee/app/services/concerns/secrets_management/secrets_permissions/`.

Each service class only defines `resource`, `client`, and `permission_class`.
The concern does the rest: it builds the permission object, converts granted actions into OpenBao capabilities, and writes the ACL policy.

A permission grant writes to two separate OpenBao policies.
A management policy covers metadata read, write, and delete, and never covers value reads.
A read-only API policy covers value reads. GitLab writes this second policy only when `read_value` is granted, and deletes it when `read_value` is not granted.

Permissions are stored as OpenBao ACL policies, not in the database.
`ProjectSecretsPermission` and `GroupSecretsPermission` are `ActiveModel::Model` objects, not `ApplicationRecord`.

## Count services and limit enforcement

These services check whether a project or group has hit its secrets limit before a create goes through.
Files: `ee/app/services/secrets_management/project_secrets_count_service.rb`, `group_secrets_count_service.rb`, and the shared `Concerns::SecretsCountService` at `ee/app/services/secrets_management/concerns/secrets_count_service.rb`.

`secrets_limit_exceeded?` reads the secrets manager's configured `secrets_limit`.
A limit of `0` is treated as unlimited.
Otherwise it asks OpenBao for a count capped at `limit + 1` and compares against the limit, so the count call never has to scan past what it needs to answer the question.

`Secrets::CreateServiceHelpers#secrets_limit_exceeded?` calls this service before writing a new secret, and each create service must implement `secrets_count_service` to return the right one:

```ruby
def secrets_count_service
  SecretsManagement::ProjectSecretsCountService.new(project, current_user)
end
```

A second, separate mechanism keeps a per-namespace count for billing: `SecretsManagement::NamespaceSecretCounts::RefreshService` (`ee/app/services/secrets_management/namespace_secret_counts/refresh_service.rb`).
Only the `secrets_stored` billing event reads this count. The GraphQL count fields still count secrets in OpenBao on every request.
Create and delete enqueue `ReconcileNamespaceSecretCountWorker` after a successful write, which calls `RefreshService.execute_for_namespace_id` to upsert a fresh count into `NamespaceSecretCount` (or delete the row if the secrets manager is gone or inactive).
Limit enforcement at write time does not use this count either.

## Rotation list services

These services list the secrets that are due, or coming due, for rotation.
Files: `ee/app/services/secrets_management/project_secrets/list_needing_rotation_service.rb`, `group_secrets/list_needing_rotation_service.rb`, and the shared `Secrets::ListNeedingRotationServiceHelpers` concern.

Each service subclasses its scope's `ListService` and includes the concern, which overrides `execute`:

1. Calls `super(include_rotation_info: true)` to get every secret with its rotation information attached.
1. Filters to secrets where `rotation_info.needs_attention?` is true.
1. Sorts by urgency: overdue secrets first, ordered oldest-created first, then approaching secrets, ordered by soonest `next_reminder_at`.

## Group vs project service differences

| Item | Project | Group |
|------|---------|-------|
| Scope attribute | `branch` (string) | `protected` (boolean) |
| Secret class | `ProjectSecret` | `GroupSecret` |
| Rotation information class | `ProjectSecretRotationInfo` | `GroupSecretRotationInfo` |
| Refresher helper location | `ee/app/services/concerns/secrets_management/project_secrets/secret_refresher_helper.rb` | `ee/app/services/secrets_management/group_secrets/secret_refresher_helper.rb` (not under `concerns/`) |
| Client method | `project_secrets_manager_client` | `group_secrets_manager_client` |

## Error handling

Services return `ServiceResponse.success(payload: ...)` or `ServiceResponse.error(message:, reason:, payload:)`.
A few reasons are used consistently enough to check in callers: `:not_found`, `:entitlement_blocked`, `:secrets_limit_exceeded`, `:already_initialized`.

The OpenBao client raises `SecretsManagement::SecretsManagerClient::ApiError` with the raw OpenBao error text.
Services rescue this in the specific spots where they can turn it into a user-facing message, for example the CAS mismatch rescue in `Secrets::UpdateServiceHelpers`.
Anywhere a service does not rescue it, the `ApiError` propagates up to the GraphQL layer.

`SecretsManagement::ErrorMapping` (`ee/lib/secrets_management/error_mapping.rb`) is the shared sanitizer for that boundary.
It recognizes permission errors and check-and-set errors by pattern, redacts any quoted OpenBao path (which can contain a secret name) before logging, and maps everything else to a generic "Internal server error."
It is applied by the mutation and resolver error handling concerns, not by the service layer itself.
For how those concerns wire it in, see [Secrets Manager GraphQL](graphql.md).

## New service checklist

1. Choose the scope: `project_secrets/` or `group_secrets/`.
1. Create the file at `ee/app/services/secrets_management/{scope}/{action}_service.rb`.
1. Inherit from `ProjectBaseService` or `GroupBaseService`.
1. Include the shared concern from `ee/app/services/concerns/secrets_management/secrets/` if one fits your action.
1. Include the scope-specific refresher helper if the service writes secrets: `ProjectSecrets::SecretRefresherHelper` or `GroupSecrets::SecretRefresherHelper`.
1. Delegate `secrets_manager` to the parent resource.
1. Implement every abstract method the concern expects. See the tables earlier on this page.
1. Wrap write operations in `with_exclusive_lease_for(secrets_manager_parent)`.
1. Return `ServiceResponse.success` or `ServiceResponse.error` consistently. Do not raise unhandled exceptions for expected failure cases.
1. Add a spec at `ee/spec/services/secrets_management/{scope}/{action}_service_spec.rb`. See [Secrets Manager testing](testing.md).
1. If the same logic is needed by both project and group services, extract it to a concern under `ee/app/services/concerns/secrets_management/secrets/` rather than duplicating it.

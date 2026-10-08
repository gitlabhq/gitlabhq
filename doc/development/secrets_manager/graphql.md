---
stage: Security Platform
group: Secrets Manager Application
info: Any user with at least the Maintainer role can merge updates to this content. For details, see <https://docs.gitlab.com/development/development_processes/#development-guidelines-review>.
title: Secrets Manager GraphQL API
ignore_in_report: true
---

Secrets Manager exposes its data and actions through GraphQL types, mutations, and resolvers under `ee/app/graphql/`.
Every mutation and resolver shares the same error handling and authorization concerns, described below.

## Types

Types live in `ee/app/graphql/types/secrets_management/`.

| Type | GraphQL name | Backed by |
|------|-------------|-----------|
| `ProjectSecretsManagerType` | `ProjectSecretsManager` | `ProjectSecretsManager` record. Exposes `status` from `effective_status`, and a `read_only` field for strict read-only mode. |
| `GroupSecretsManagerType` | `GroupSecretsManager` | `GroupSecretsManager` record. |
| `ProjectSecretType` | `ProjectSecret` | An `ActiveModel::Model` secret built from an OpenBao response. |
| `GroupSecretType` | `GroupSecret` | Same, for group secrets. |
| `SecretRotationInfoType` | `SecretRotationInfo` | `ProjectSecretRotationInfo` or `GroupSecretRotationInfo`. Authorization is handled by the parent secret type, not this type. |
| `ProjectSecretsPermissionType` | `ProjectSecretsPermission` | A project secrets permission. Includes `SecretsPermissionInterface`. |
| `GroupSecretsPermissionType` | `GroupSecretsPermission` | Same, for group permissions. |
| `EntitlementType` | `SecretsManagerEntitlement` | The `SecretsManagement::Entitlement` value object. See [Entitlement states](fulfillment.md#entitlement-states). |
| `EnrollmentType` | `SecretsManagerEnrollment` | A `SecretsManagement::NamespaceEnrollment` or the instance-wide enrollment. |

`SecretsPermissionInterface`, at `ee/app/graphql/types/secrets_management/secrets_permission_interface.rb`, is a shared `ActiveSupport::Concern` that adds the `principal`, `actions`, `grantedBy`, and `expiredAt` fields to both permission types.

Permission-specific support types live in `ee/app/graphql/types/secrets_management/permissions/`: `PrincipalType`, `PrincipalInputType`, `PrincipalTypeEnum`, `ActionEnum`, and `SecretPermissionType`.

### Enums

| Enum | Values |
|------|--------|
| `ProjectSecretsManagerStatusEnum`, `GroupSecretsManagerStatusEnum` | Based on `BaseSecretsManagerStatusEnum`. |
| `SecretStatusEnum` | Computed lifecycle status of a secret, from its timestamps. |
| `SecretRotationStatusEnum` | `OVERDUE`, `APPROACHING`, `OK`. |
| `EntitlementStateEnum` | Mirrors the `SecretsManagement::Entitlement` states. |
| `EntitlementBlockedReasonEnum` | Mirrors the entitlement `blocked_reason` values. |
| `WriteActionDenialReasonEnum` | Returned on the `reason` field when a mutation is denied for entitlement reasons, and on the `writeDenialReason` field of `ProjectSecretsManagerType` and `GroupSecretsManagerType`. |

### Authorization on types

Types declare a Rails policy ability with `authorize`, for example `authorize :read_project_secrets` on `ProjectSecretType`.
Some types also declare `authorize_granular_token`. This states the granular token permission a personal access token must carry to read that type over the GraphQL API. For example, `ProjectSecretsManagerType` declares `authorize_granular_token permissions: :read_secrets_manager, boundary: :project, boundary_type: :project`.
A type with no per-object policy, such as `SecretRotationInfoType`, disables the authorization check with a `rubocop:disable Graphql/AuthorizeTypes` comment and relies on its parent type's authorization.

## Mutations

Mutations live in `ee/app/graphql/mutations/secrets_management/`, grouped by area.

### Project and group secrets managers

| Mutation file | GraphQL name | Rails ability | Service |
|---------------|-------------|----------------|---------|
| `project_secrets_managers/initialize.rb` | `ProjectSecretsManagerInitialize` | `:provision_secrets_manager` | `ProjectSecretsManagers::InitializeService` |
| `project_secrets_managers/deprovision.rb` | `ProjectSecretsManagerDeprovision` | `:admin_project_secrets_manager` | `ProjectSecretsManagers::InitiateDeprovisionService` |
| `group_secrets_managers/initialize.rb` | `GroupSecretsManagerInitialize` | `:provision_secrets_manager` | `GroupSecretsManagers::InitializeService` |
| `group_secrets_managers/deprovision.rb` | `GroupSecretsManagerDeprovision` | `:deprovision_secrets_manager` | `GroupSecretsManagers::InitiateDeprovisionService` |

### Project and group secrets

| Mutation file | GraphQL name | Rails ability |
|---------------|-------------|----------------|
| `project_secrets/create.rb` | `ProjectSecretCreate` | `:create_project_secrets` |
| `project_secrets/update.rb` | `ProjectSecretUpdate` | `:update_project_secrets` |
| `project_secrets/delete.rb` | `ProjectSecretDelete` | `:delete_project_secrets` |
| `group_secrets/create.rb` | `GroupSecretCreate` | `:create_secret` |
| `group_secrets/update.rb` | `GroupSecretUpdate` | `:update_secret` |
| `group_secrets/delete.rb` | `GroupSecretDelete` | `:delete_secret` |

Project and group secret mutations differ in a few small ways.

| Difference | Project | Group |
|-----------|---------|-------|
| Resolver include | `include ResolvesProject` | `include ResolvesGroup` |
| `find_object` argument | `project_path:` | `group_path:` |
| Scope-specific argument | `branch` (String) | `protected` (Boolean) |
| Return field | `project_secret` | `group_secret` |
| Internal event name on create | `create_ci_secret` | `create_group_ci_secret` |

The GraphQL argument for the secret value is named `secret`, but the service call parameter is named `value`.
The rename happens in `resolve`, for example `.execute(value: secret, ...)` in `project_secrets/create.rb`.
Follow this convention for any new mutation that accepts a secret value.

### Permissions

| Mutation file | GraphQL name |
|---------------|-------------|
| `project_secrets_permissions/update.rb` | `ProjectSecretsPermissionUpdate` |
| `project_secrets_permissions/delete.rb` | `ProjectSecretsPermissionDelete` |
| `group_secrets_permissions/update.rb` | `GroupSecretsPermissionUpdate` |
| `group_secrets_permissions/delete.rb` | `GroupSecretsPermissionDelete` |

### Entitlement, trials, and enrollment

| Mutation file | GraphQL name |
|---------------|-------------|
| `enable_add_on.rb` | `SecretsManagerEnableAddOn` |
| `instance_enable_add_on.rb` | `SecretsManagerInstanceEnableAddOn` |
| `start_trial.rb` | `SecretsManagerStartTrial` |
| `instance_start_trial.rb` | `SecretsManagerInstanceStartTrial` |
| `refresh_entitlement.rb` | `SecretsManagerRefreshEntitlement` |
| `instance_refresh_entitlement.rb` | `SecretsManagerInstanceRefreshEntitlement` |
| `enrollment/namespace_enroll.rb` | `NamespaceSecretsManagerEnroll` |
| `enrollment/namespace_unenroll.rb` | `NamespaceSecretsManagerUnenroll` |
| `enrollment/instance_enroll.rb` | `InstanceSecretsManagerEnroll` |
| `enrollment/instance_unenroll.rb` | `InstanceSecretsManagerUnenroll` |

For what these mutations change, see [What each state allows](fulfillment.md#what-each-state-allows).

## Resolvers

Resolvers live in `ee/app/graphql/resolvers/secrets_management/`.

| Resolver | Purpose |
|----------|---------|
| `ProjectSecretsManagerResolver`, `GroupSecretsManagerResolver` | Fetch the secrets manager status for a project or group. |
| `ProjectSecretsResolver`, `GroupSecretsResolver` | List secrets. Use `lookahead` to skip loading rotation information unless the query selects it. |
| `ProjectSecretResolver`, `GroupSecretResolver` | Fetch a single secret. |
| `ProjectSecretsCountResolver`, `GroupSecretsCountResolver` | Count secrets. |
| `ProjectSecretsPermissionsResolver`, `GroupSecretsPermissionsResolver` | List permissions. |
| `ProjectSecrets::ListNeedingRotationResolver`, `GroupSecrets::ListNeedingRotationResolver` | List secrets due or approaching rotation. |
| `Permissions::SecretPermissionsResolver` | List secret permissions through the newer permission type. |
| `OpenbaoHealthResolver` | Check OpenBao server health. |
| `NamespaceEnrollmentResolver`, `InstanceEnrollmentResolver` | Fetch enrollment state. |
| `InstanceEntitlementResolver` | Fetch the instance-level entitlement. |

### Lookahead optimization

`ProjectSecretsResolver` and `GroupSecretsResolver` take `extras [:lookahead]` and only ask the list service to include rotation information when the query asks for it:

```ruby
def resolve(lookahead:, project_path:)
  result = ListService.new(project, current_user)
    .execute(include_rotation_info: include_rotation_info?(lookahead))
end

def include_rotation_info?(lookahead)
  lookahead.selection(:nodes).selects?(:rotation_info) ||
    lookahead.selection(:edges).selection(:node).selects?(:rotation_info)
end
```

## Shared mutation and resolver concerns

Every mutation and resolver must include an error handling concern.
Both concerns wrap `resolve` with the same `ErrorWrapper`, defined once in `SecretsManagement::GraphqlErrorHandling` at `ee/lib/secrets_management/graphql_error_handling.rb`.

| Concern | Module | Included by |
|---------|--------|--------------|
| Mutation error handling | `SecretsManagement::MutationErrorHandling` (`ee/app/graphql/mutations/concerns/secrets_management/mutation_error_handling.rb`) | Mutations that work with OpenBao or Secrets Manager services. The trial, add-on, and refresh entitlement mutations, which only call CustomersDot, do not include it. |
| Resolver error handling | `SecretsManagement::ResolverErrorHandling` (`ee/app/graphql/resolvers/concerns/secrets_management/resolver_error_handling.rb`) | All resolvers. |

Write mutations also include two more concerns:

| Concern | Module | What it does |
|---------|--------|---------------|
| Active namespace check | `SecretsManagement::RequiresActiveNamespace` (`ee/app/graphql/mutations/concerns/secrets_management/requires_active_namespace.rb`) | Adds `raise_if_namespace_inactive!`, which blocks writes on an archived group or project, or one pending deletion. |
| Write entitlement enforcement | `SecretsManagement::EnforcesWriteEntitlement` (`ee/app/graphql/mutations/concerns/secrets_management/enforces_write_entitlement.rb`) | Adds a `ready?` hook that short-circuits a write with a structured `reason` when entitlement denies it. Opt in with `enforces_write_entitlement_for :payload_key, find_by: :project_path` (or `:group_path`). |

Secret delete mutations do not include `EnforcesWriteEntitlement`. Permission delete and deprovision mutations do.

## Authorization

Authorization on a mutation or resolver combines up to three checks.

1. `authorize :ability_name`. A Rails policy ability, checked through `authorized_find!` in the `resolve` method.
1. `authorize_granular_token permissions: ..., boundary_argument: ..., boundary_type: ...` (or `boundary:` for a fixed boundary such as `:instance`). States which granular token permission a personal access token must carry. Multiple permissions can be listed, for example `instance_enable_add_on.rb` requires both `:enable_secrets_manager_add_on` and `:read_secrets_manager` because its payload also returns an entitlement.
1. `enforces_write_entitlement_for` on write mutations, described above.

Fields can carry their own `authorize` too, independent of the type's own authorization, as seen on `SecretsPermissionInterface`.

## How errors reach the client

`SecretsManagement::ErrorMapping`, at `ee/lib/secrets_management/error_mapping.rb`, is included by `GraphqlErrorHandling` and never exposes a raw OpenBao error to the client.

- A permission error, or an exact `"not found"` message, becomes `raise_resource_not_available_error!`.
- A check-and-set mismatch becomes "This resource was recently modified. Refresh the page and try again to avoid overwriting newer changes."
- Any other error becomes "Internal server error.", and is reported through `Gitlab::ErrorTracking.track_exception` with secret paths redacted from the message first.

A mutation's own `resolve` method also returns structured, user-facing errors directly in its GraphQL response, independent of this rescue path:

```ruby
if result.success?
  { project_secret: result.payload[:secret], errors: [] }
else
  { project_secret: nil, errors: error_messages(result, [:secret]) }
end
```

## Frontend GraphQL documents

Frontend queries and mutations live under `ee/app/assets/javascripts/ci/secrets/graphql/`.

- Queries: `ee/app/assets/javascripts/ci/secrets/graphql/queries/`, for example `get_project_secrets.query.graphql` and `get_project_secret_manager_status.query.graphql`.
- Mutations: `ee/app/assets/javascripts/ci/secrets/graphql/mutations/`, for example `create_project_secret.mutation.graphql` and `enable_secret_manager.mutation.graphql`.

For the Vue components that use these documents, see [Secrets Manager frontend development](frontend.md).

## New mutation checklist

1. Create the service the mutation calls, if it does not exist yet.
1. Create the mutation file at `ee/app/graphql/mutations/secrets_management/{scope}/{action}.rb`.
1. Include the required concerns: `ResolvesProject` or `ResolvesGroup`, `SecretsManagement::MutationErrorHandling` if the mutation works with OpenBao or a Secrets Manager service, and, for a write, `SecretsManagement::RequiresActiveNamespace` and `SecretsManagement::EnforcesWriteEntitlement`.
1. Track internal events in the service when other entry points also run it. For example, `InitializeServiceHelpers` tracks the enable event, so the trial and add-on mutations emit it too.
1. Compare the mutation with its closest existing peer, for example the project version of a group mutation, or `EnableAddOn` for a billing mutation. Include the same concerns, authorization, and feature checks, or note why not.
1. Set `authorize :ability_name` with an existing ability from `EE::ProjectPolicy` or `EE::GroupPolicy`, or add a new one.
1. Set `authorize_granular_token` with the permission a personal access token needs, and its `boundary_type`.
1. For a write mutation, call `enforces_write_entitlement_for :payload_key, find_by: :project_path` (or `:group_path`).
1. Mount the mutation with `mount_mutation` in `ee/app/graphql/ee/types/mutation_type.rb`, next to the other `SecretsManagement` mutations.
1. Add the internal event definition under `config/events/` if the mutation tracks a new event.
1. Create the frontend `.mutation.graphql` file under `ee/app/assets/javascripts/ci/secrets/graphql/mutations/`.
1. Regenerate the GraphQL reference documentation and schema with `bundle exec rake gitlab:graphql:compile_docs`, or `bundle exec rake gitlab:graphql:update_all` to also update the schema dump.
1. Add a request spec under `ee/spec/requests/api/graphql/secrets_management/`. See [Secrets Manager testing](testing.md).
1. Add a frontend spec under `ee/spec/frontend/ci/secrets/`.

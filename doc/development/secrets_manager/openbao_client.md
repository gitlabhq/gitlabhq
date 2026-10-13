---
stage: Security Platform
group: Secrets Manager Application
info: Any user with at least the Maintainer role can merge updates to this content. For details, see <https://docs.gitlab.com/development/development_processes/#development-guidelines-review>.
title: Secrets Manager OpenBao client and authentication
ignore_in_report: true
---

GitLab talks to OpenBao over HTTP through `SecretsManagement::SecretsManagerClient`.
Every request carries a JWT that GitLab signs itself.
OpenBao checks each JWT with a CEL (Common Expression Language) program and turns the claims into a set of ACL policies for that request.

For the two authorization layers (Rails policy plus OpenBao ACL) and the OpenBao namespace layout, see [Secrets Manager development guidelines](_index.md).

## SecretsManagerClient

File: `ee/lib/secrets_management/secrets_manager_client.rb`

The client wraps Faraday and does not pre-authenticate.
Every request carries OpenBao's inline auth headers, so each call authenticates and executes in one round trip:

- `X-Vault-Inline-Auth-Path`: the login path to use, for example `auth/user_jwt/cel/login`.
- `X-Vault-Inline-Auth-Parameter-token`: the JWT, base64-encoded.
- `X-Vault-Inline-Auth-Parameter-role`: the role name, base64-encoded (omitted if the role is blank).

`SecretsManagerClient.new` takes:

| Parameter | Default | Purpose |
|-----------|---------|---------|
| `jwt` | None | The encoded JWT to send for inline auth. Required. |
| `role` | `'app'` | The JWT role to authenticate as. |
| `auth_namespace` | `""` | The OpenBao namespace the login path is relative to. |
| `auth_mount` | `'gitlab_rails_jwt'` | The JWT auth mount to authenticate against. |
| `use_cel_auth` | `false` | Authenticate at the mount's `cel/login` path instead of `login`. |
| `namespace` | `""` | The OpenBao namespace that data-plane requests are relative to. |
| `timeout` | `nil` | Per-request open and read timeout in seconds. |

The client host and base path come from `SecretsManagerClient.configure`, set in `ee/config/initializers/secrets_manager.rb`.

### Namespacing

`with_namespace` returns a new client scoped to a different OpenBao namespace.
`with_auth_namespace` returns one that logs in against a different namespace than it operates in:

```ruby
client = SecretsManagerClient.new(jwt: jwt)
org_client = client.with_namespace(secrets_manager.org_path)
project_client = client.with_namespace(secrets_manager.full_project_namespace_path)
```

`with_namespace` replaces the client's namespace instead of appending to it, so always pass the full slash-joined path from the root.

### Two client construction patterns

- A privileged management client: built from a `GlobalSecretsManagerJwt` subclass, using the default `role: 'app'` and `auth_mount: 'gitlab_rails_jwt'`, then scoped with `with_namespace` to the full path of the org, root, or entity level namespace it operates on. `ProjectBaseService#base_secrets_manager_client` and `GroupBaseService#base_secrets_manager_client` build this client.
- A CEL-scoped client for one specific mount: built from a `*UserJwt`, `*ApiJwt`, or `PipelineJwt`, passing that mount's `role`, `auth_mount`, and `auth_namespace` explicitly, with `use_cel_auth: true`. `ProjectBaseService#user_client` is an example.

### Method groups

| Group | Methods |
|-------|---------|
| Namespace management | `enable_namespace`, `disable_namespace` |
| Secrets engine management | `enable_secrets_engine`, `disable_secrets_engine` |
| Auth engine management | `enable_auth_engine`, `disable_auth_engine`, `configure_jwt` |
| JWT role configuration | `update_gitlab_rails_jwt_role`, `update_jwt_role`, `read_jwt_role`, `delete_jwt_role` |
| CEL role configuration | `update_jwt_cel_role`, `read_jwt_cel_role`, `delete_jwt_cel_role`, `cel_login_jwt` |
| Secret values and metadata | `update_kv_secret`, `update_kv_secret_metadata`, `read_secret_metadata`, `delete_kv_secret`, `list_secrets`, `count_secrets` |
| ACL policies | `get_policy`, `set_policy`, `delete_policy`, `list_policies`, `list_project_policies` |
| Capability resolution | `capabilities_self` |
| Recovery and health | `init_rotate_recovery`, `cancel_rotate_recovery`, `server_available?`, `generate_root_token_status`, `init_generate_root_token`, `update_generate_root_token`, `cancel_generate_root_token` |

`capabilities_self` is the one method that does not use inline auth.
`sys/capabilities-self` resolves the caller by looking up a persisted token, but an inline-auth token is never written to the token store.
So the client authenticates explicitly first (`login_with_jwt`), calls `capabilities-self` with the resulting token over `X-Vault-Token`, then revokes that token.

### Error types

The client raises one of four error classes, depending on what OpenBao or the connection returned.

| Class | Raised for |
|-------|------------|
| `ApiError` | A response body with an `errors` array, or a 4xx that OpenBao's `raise_error` middleware turns into a client error. |
| `AuthenticationError` | Inline auth failed. Signaled by the `X-Vault-Inline-Auth-Failed` response header rather than always as a distinct status code. |
| `ServiceUnavailableError` | 5xx responses, or a request timeout. |
| `ConnectionError` | Any other Faraday connection failure. |

## JWT class hierarchy

Secrets Manager mints a different JWT subclass for each situation, arranged in this hierarchy.

Directory: `ee/lib/secrets_management/`

```plaintext
Gitlab::Ci::JwtBase
  GlobalSecretsManagerJwt (privileged, system-level)
    ProjectSecretsManagerJwt
      ProjectUserJwt
        ProjectApiJwt
    GroupSecretsManagerJwt
      GroupUserJwt
        GroupApiJwt

Gitlab::Ci::JwtV2
  PipelineJwt
```

| Class | File | Used for | Distinguishing claims |
|-------|------|----------|------------------------|
| `GlobalSecretsManagerJwt` | `global_secrets_manager_jwt.rb` | System-level operations not scoped to a project or group, for example recovery key generation. | `sub: 'gitlab_secrets_manager'`, `secrets_manager_scope: 'privileged'`. 30-second TTL. |
| `ProjectSecretsManagerJwt` | `project_secrets_manager_jwt.rb` | Base class for project-scoped privileged operations (provisioning, management client). | Adds project and user audit claims through `JSONWebToken::UserProjectTokenClaims`. |
| `ProjectUserJwt` | `project_user_jwt.rb` | Secret CRUD through the UI and GraphQL. | `sub: "user:{username}"`, `secrets_manager_scope: 'user'`, `role_id`, `member_role_id`. |
| `ProjectApiJwt` | `project_api_jwt.rb` | Non-CI API access to a project's secrets. | Same claims as `ProjectUserJwt`, plus `secrets_manager_scope: 'api'` and `auth_via` (the token type used to call the API). |
| `GroupSecretsManagerJwt` | `group_secrets_manager_jwt.rb` | Base class for group-scoped privileged operations. | `group_id`, `group_path`, `root_group_id`, `organization_id`, `organization_path`. |
| `GroupUserJwt` | `group_user_jwt.rb` | Secret CRUD on a group through the UI and GraphQL. | Same shape as `ProjectUserJwt`. |
| `GroupApiJwt` | `group_api_jwt.rb` | Non-CI API access to a group's secrets. | Same shape as `ProjectApiJwt`. |
| `PipelineJwt` | `pipeline_jwt.rb` | CI runners fetching secrets during a pipeline job. | `secrets_manager_scope: 'pipeline'`, `project_group_ids` (the project's group ancestry, for group-level secret access). |

`role_id` is the user's effective access level, read with `max_member_access_for_project` for a project and `max_member_access_for_group` (share-aware, `only_concrete_membership: true`) for a group.
`member_role_id` walks the project's or group's ancestors to find the closest custom role assignment.

`PipelineJwt` extends `Gitlab::Ci::JwtV2` instead of the `GlobalSecretsManagerJwt` branch, and overrides `verify_path_not_burned!` to do nothing, because OpenBao validates project identity from the `project_id` and `project_group_ids` claims, not from the token's subject prefix.

## Auth mounts

Each provisioned secrets manager namespace has three JWT auth mounts, all authenticating through CEL roles:

| Mount | Role | Used by | Policies resolved |
|-------|------|---------|--------------------|
| `pipeline_jwt` | `all_pipelines` | CI runners (`PipelineJwt`) | `pipelines/global`, plus environment, branch, or combined policies. |
| `user_jwt` | `all_users` | UI and GraphQL CRUD (`*UserJwt`) | `users/direct/user_{id}`, `users/direct/member_role_{id}`, `users/roles/{access_level}`. |
| `api_jwt` | `all_api` | Non-CI API access (`*ApiJwt`) | Same principal policies as `user_jwt`, under the `api/` prefix, read-only. |

A fourth mount, `gitlab_rails_jwt` with role `app`, is the client's default and is used for privileged management operations (provisioning, namespace and policy management) rather than for a CEL-validated principal.

All three CEL mounts are configured the same way during provisioning (`ProjectSecretsManagers::ProvisionService#enable_auth`, mirrored for groups): enable the auth engine, call `configure_jwt` to point it at the GitLab OIDC issuer, then call `update_jwt_cel_role` with that scope's CEL program.
`ApiAuthConfigurator` holds this logic for the `api_jwt` mount specifically.
The provision flow and the API mount backfill task both call it, so the two cannot drift apart.

## CEL programs

CEL programs are generated per scope (project or group) by model concerns under `ee/app/models/secrets_management/{project,group}_secrets_managers/`:

| Concern | Method | Mount |
|---------|--------|-------|
| `PipelineHelper` | `pipeline_auth_cel_program` | `pipeline_jwt` |
| `UserHelper` | `user_auth_cel_program` | `user_jwt` |
| `ApiHelper` | `api_auth_cel_program` | `api_jwt` |

Each program is a hash of CEL `variables` plus a final `expression`.
The expression validates the claims (subject prefix, `secrets_manager_scope`, project or group ID, audience) and returns either an error string or a `pb.Auth` object listing the OpenBao policies to attach and metadata to record.

Policy assignment differs by scope:

- Pipeline CEL (project): `pipelines/global` always, plus `pipelines/env/{hex(environment)}`, `pipelines/branch/{hex(ref)}`, and `pipelines/combined/env/{hex}/branch/{hex}` when those claims are set.
- Pipeline CEL (group): policies are named by protection level instead of branch, using `ci_policy_name_for_environment(environment, protected:)`, because group-level CI access is not scoped to one branch.
- User and API CEL (project and group): `users/direct/user_{id}` (or `api/users/direct/user_{id}`), `users/direct/member_role_{id}`, and `users/roles/{access_level}`, built from whichever of `uid`, `mrid`, and `rid` are present in the claims.

The user and API CEL programs also read an optional `secrets_manager_token_ttl` claim (seconds) to set the minted OpenBao token's lease.
It defaults to five minutes if the claim is missing, null, or not positive.

## ACL policies

Files: `ee/lib/secrets_management/acl_policy.rb`, `ee/lib/secrets_management/acl_policy_path.rb`

Two classes model an OpenBao ACL policy in Ruby.
`AclPolicy` holds a policy `name` and a map of path to `AclPolicyPath`.
`AclPolicyPath` holds `capabilities` (a set, for example `create`, `read`, `update`, `delete`, `list`) plus optional `allowed_parameters`, `denied_parameters`, `required_parameters`, `granted_by` (an OpenBao comment field, set to a user ID), and `expired_at`.
`AclPolicy#to_openbao_attributes` serializes to the JSON shape OpenBao's ACL policy API expects.
`SecretsManagerClient#get_policy` and `#set_policy` read and write a named policy.

### Policy naming

| Method | Where | Produces |
|--------|-------|----------|
| `policy_name_for_principal(principal_type:, principal_id:)` | `SecretsManagers::UserHelper` | `users/direct/user_{id}`, `users/direct/member_role_{id}`, or `users/roles/{access_level}`, for the management (UI) mount. |
| `api_policy_name_for_principal(principal_type:, principal_id:)` | `SecretsManagers::ApiHelper` | The same name prefixed with `api/`, for the read-only API mount. |
| `ci_policy_name(environment, branch)` and its `_global`, `_env`, `_branch`, `_combined` variants | `ProjectSecretsManagers::PipelineHelper` | `pipelines/global`, `pipelines/env/{hex}`, `pipelines/branch/{hex}`, or `pipelines/combined/env/{hex}/branch/{hex}`. |
| `ci_policy_name_for_environment(environment, protected:)` | `GroupSecretsManagers::PipelineHelper` | `pipelines/combined/{protected or unprotected}/{global or env/{hex}}`. |

Environment and branch values are hex-encoded with `BaseSecretsManager#hex` (`value.unpack1('H*')`) before they go into a policy name, because OpenBao policy names cannot safely contain arbitrary characters.

### When policies are written

- Provisioning writes one policy per default role (`SecretsManagers::DefaultRolePoliciesHelper#create_default_role_policies`). Project provisioning grants Owner (`read`, `write`, `delete`), Maintainer (`read`, `write`), and Developer (`read`, `create`) on the management mount's paths. Developer gets `create` but not `write`, so a Developer can add a secret but cannot change one that already exists. Group provisioning grants Owner only, because a group grant reaches the pipelines of every descendant project.
- Granting or updating a secrets permission (`SecretsPermissions::UpdateServiceHelpers#store_permission`) writes two policies: a management policy (metadata read, write, delete, never a value read) and, only if `read_value` is granted, a read-only API policy under the `api/` prefix. If no API capability remains, the API policy is deleted instead of written empty.
- Every policy write replaces the full capability set for that policy's paths before adding the current set back, so revoking a capability clears it rather than leaving a stale grant.

## Non-CI API access

Files: `ee/lib/api/secrets_management/access_tokens.rb`, `ee/app/services/secrets_management/api_access/issue_token_service.rb`

A REST endpoint mints a short-lived JWT that a client presents to OpenBao directly, without going through GitLab for each read:

- `POST /projects/:id/secrets_manager/access_token`
- `POST /groups/:id/secrets_manager/access_token`

Both routes are behind a feature flag and the `create_secrets_manager_api_jwt` authorization ability, and require the secrets manager to be `active`.
Access is limited to token-based authentication (personal access token, project or group access token, service account token, or OAuth).
A browser session is rejected because it leaves no revocable credential.

`ApiAccess::IssueTokenService` builds a `ProjectApiJwt` or `GroupApiJwt` (five-minute TTL).
It returns connection details shaped to match the `external-secrets.io` Vault provider format, so a client such as External Secrets Operator can use the response directly: server URL, namespace, KV mount path, secrets base path (`explicit`), the CEL authentication path (`api_jwt/cel`), the role (`all_api`), and the token itself.

There is no public commitment yet to non-CI REST read or write endpoints beyond minting this access token. Writes still go through the existing GraphQL mutations.

---
stage: Software Supply Chain Security
group: Pipeline Security
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Use HashiCorp Vault secrets in GitLab CI/CD
---

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

WARNING:
Authenticating with `CI_JOB_JWT` was [deprecated in GitLab 15.9 and removed in GitLab 17.0](../../update/deprecations.md#old-versions-of-json-web-tokens-are-deprecated).
Use [ID tokens to authenticate with HashiCorp Vault](hashicorp_vault.md#example)
instead, as demonstrated on this page.

NOTE:
Starting in Vault 1.17, [JWT auth login requires bound audiences on the role](https://developer.hashicorp.com/vault/docs/upgrading/upgrade-to-1.17.x#jwt-auth-login-requires-bound-audiences-on-the-role)
when the JWT contains an `aud` claim. The `aud` claim can be a single string or a list of strings.

This tutorial demonstrates how to authenticate, configure, and read secrets with HashiCorp's Vault from GitLab CI/CD.

## Prerequisites

This tutorial assumes you are familiar with GitLab CI/CD and Vault.

To follow along, you must have:

- An account on GitLab.
- Access to a running Vault server (at least v1.2.0) to configure authentication and to create roles and policies.
  For HashiCorp Vaults, this can be the Open Source or Enterprise version.

NOTE:
You must replace the `vault.example.com` URL below with the URL of your Vault server,
and `gitlab.example.com` with the URL of your GitLab instance.

## How it works

ID tokens are JSON Web Tokens (JWTs) used for OIDC authentication with third-party services.
If a job has at least one ID token defined, the `secrets` keyword automatically uses that token
to authenticate with Vault.

The following fields are included in the JWT:

| Field                   | When                                       | Description |
|-------------------------|--------------------------------------------|-------------|
| `jti`                   | Always                                     | Unique identifier for this token |
| `iss`                   | Always                                     | Issuer, the domain of your GitLab instance |
| `iat`                   | Always                                     | Issued at   |
| `nbf`                   | Always                                     | Not valid before |
| `exp`                   | Always                                     | Expires at  |
| `sub`                   | Always                                     | Subject (job ID) |
| `namespace_id`          | Always                                     | Use this to scope to group or user level namespace by ID |
| `namespace_path`        | Always                                     | Use this to scope to group or user level namespace by path |
| `project_id`            | Always                                     | Use this to scope to project by ID |
| `project_path`          | Always                                     | Use this to scope to project by path |
| `user_id`               | Always                                     | ID of the user executing the job |
| `user_login`            | Always                                     | Username of the user executing the job |
| `user_email`            | Always                                     | Email of the user executing the job |
| `pipeline_id`           | Always                                     | ID of this pipeline |
| `pipeline_source`       | Always                                     | [Pipeline source](../jobs/job_rules.md#common-if-clauses-with-predefined-variables) |
| `job_id`                | Always                                     | ID of this job |
| `ref`                   | Always                                     | Git ref for this job |
| `ref_type`              | Always                                     | Git ref type, either `branch` or `tag` |
| `ref_path`              | Always                                     | Fully qualified ref for the job. For example, `refs/heads/main`. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/119075) in GitLab 16.0. |
| `ref_protected`         | Always                                     | `true` if this Git ref is protected, `false` otherwise |
| `environment`           | Job specifies an environment               | Environment this job specifies |
| `groups_direct`         | User is a direct member of 0 to 200 groups | The paths of the user's direct membership groups. Omitted if the user is a direct member of more than 200 groups. ([Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/435848) in GitLab 16.11). |
| `environment_protected` | Job specifies an environment               | `true` if specified environment is protected, `false` otherwise |
| `deployment_tier`       | Job specifies an environment               | [Deployment tier](../environments/_index.md#deployment-tier-of-environments) of environment this job specifies ([introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/363590) in GitLab 15.2) |
| `environment_action`    | Job specifies an environment               | [Environment action (`environment:action`)](../environments/_index.md) specified in the job. ([Introduced](https://gitlab.com/gitlab-org/gitlab/-/) in GitLab 16.5) |

Example JWT payload:

```json
{
  "jti": "c82eeb0c-5c6f-4a33-abf5-4c474b92b558",
  "iss": "gitlab.example.com",
  "iat": 1585710286,
  "nbf": 1585798372,
  "exp": 1585713886,
  "sub": "job_1212",
  "namespace_id": "1",
  "namespace_path": "mygroup",
  "project_id": "22",
  "project_path": "mygroup/myproject",
  "user_id": "42",
  "user_login": "myuser",
  "user_email": "myuser@example.com",
  "pipeline_id": "1212",
  "pipeline_source": "web",
  "job_id": "1212",
  "ref": "auto-deploy-2020-04-01",
  "ref_type": "branch",
  "ref_path": "refs/heads/auto-deploy-2020-04-01",
  "ref_protected": "true",
  "groups_direct": ["mygroup/mysubgroup", "myothergroup/myothersubgroup"],
  "environment": "production",
  "environment_protected": "true",
  "environment_action": "start"
}
```

The JWT is encoded by using RS256 and signed with a dedicated private key. The expire time
for the token is set to job's timeout, if specified, or 5 minutes if it is not.
The key used to sign this token may change without any notice. In such case retrying the job
generates new JWT using the current signing key.

You can use this JWT for authentication with a Vault server that is configured to allow
the JWT authentication method. Provide your GitLab instance's base URL
(for example `https://gitlab.example.com`) to your Vault server as the `oidc_discovery_url`.
The server can then retrieve the keys for validating the token from your instance.

When configuring roles in Vault, you can use [bound claims](https://developer.hashicorp.com/vault/docs/auth/jwt#bound-claims)
to match against the JWT claims and restrict which secrets each CI/CD job has access to.

To communicate with Vault, you can use either its CLI client or perform API requests (using `curl` or another client).

## Example

WARNING:
JWTs are credentials, which can grant access to resources. Be careful where you paste them!

Let's say you have the passwords for your staging and production databases stored in a Vault server
that is running on `http://vault.example.com:8200`. Your staging password is `pa$$w0rd`
and your production password is `real-pa$$w0rd`.

```shell
$ vault kv get -field=password secret/myproject/staging/db
pa$$w0rd

$ vault kv get -field=password secret/myproject/production/db
real-pa$$w0rd
```

To configure your Vault server, start by enabling the [JWT Auth](https://developer.hashicorp.com/vault/docs/auth/jwt) method:

```shell
$ vault auth enable jwt
Success! Enabled jwt auth method at: jwt/
```

Then create policies that allow you to read these secrets (one for each secret):

```shell
$ vault policy write myproject-staging - <<EOF
# Policy name: myproject-staging
#
# Read-only permission on 'secret/myproject/staging/*' path
path "secret/myproject/staging/*" {
  capabilities = [ "read" ]
}
EOF
Success! Uploaded policy: myproject-staging

$ vault policy write myproject-production - <<EOF
# Policy name: myproject-production
#
# Read-only permission on 'secret/myproject/production/*' path
path "secret/myproject/production/*" {
  capabilities = [ "read" ]
}
EOF
Success! Uploaded policy: myproject-production
```

You also need roles that link the JWT with these policies.

For example, one role for staging named `myproject-staging`. The [bound claims](https://developer.hashicorp.com/vault/api-docs/auth/jwt#bound_claims)
is configured to only allow the policy to be used for the `main` branch in the project with ID `22`:

```shell
$ vault write auth/jwt/role/myproject-staging - <<EOF
{
  "role_type": "jwt",
  "policies": ["myproject-staging"],
  "token_explicit_max_ttl": 60,
  "user_claim": "user_email",
  "bound_audiences": "https://vault.example.com",
  "bound_claims": {
    "project_id": "22",
    "ref": "main",
    "ref_type": "branch"
  }
}
EOF
```

And one role for production named `myproject-production`. The `bound_claims` section
for this role only allows protected branches that match the `auto-deploy-*` pattern to access the secrets.

```shell
$ vault write auth/jwt/role/myproject-production - <<EOF
{
  "role_type": "jwt",
  "policies": ["myproject-production"],
  "token_explicit_max_ttl": 60,
  "user_claim": "user_email",
  "bound_audiences": "https://vault.example.com",
  "bound_claims_type": "glob",
  "bound_claims": {
    "project_id": "22",
    "ref_protected": "true",
    "ref_type": "branch",
    "ref": "auto-deploy-*"
  }
}
EOF
```

Combined with [protected branches](../../user/project/repository/branches/protected.md),
you can restrict who is able to authenticate and read the secrets.

Any of the claims [included in the JWT](#how-it-works) can be matched against a list of values
in the bound claims. For example:

```json
"bound_claims": {
  "user_login": ["alice", "bob", "mallory"]
}

"bound_claims": {
  "ref": ["main", "develop", "test"]
}

"bound_claims": {
  "namespace_id": ["10", "20", "30"]
}

"bound_claims": {
  "project_id": ["12", "22", "37"]
}
```

- If only `namespace_id` is used, all projects in the namespace are allowed. Nested projects are not included,
  so their namespace IDs must also be added to the list if needed.
- If both `namespace_id` and `project_id` are used, Vault first checks if the project's namespace
  is in `namespace_id` then checks if the project is in `project_id`.

[`token_explicit_max_ttl`](https://developer.hashicorp.com/vault/api-docs/auth/jwt#token_explicit_max_ttl)
specifies that the token issued by Vault, upon successful authentication, has a hard lifetime limit of 60 seconds.

[`user_claim`](https://developer.hashicorp.com/vault/api-docs/auth/jwt#user_claim)
specifies the name for the Identity alias created by Vault upon a successful login.

[`bound_claims_type`](https://developer.hashicorp.com/vault/api-docs/auth/jwt#bound_claims_type)
configures the interpretation of the `bound_claims` values. If set to `glob`, the values are interpreted as globs,
with `*` matching any number of characters.

The claim fields listed in [the table above](#how-it-works) can also be accessed for
[Vault's policy path templating](https://developer.hashicorp.com/vault/tutorials/policies/policy-templating?in=vault%2Fpolicies)
purposes by using the accessor name of the JWT auth in Vault.
The [mount accessor name](https://developer.hashicorp.com/vault/tutorials/auth-methods/identity#step-1-create-an-entity-with-alias)
(`ACCESSOR_NAME` in the example below) can be retrieved by running `vault auth list`.

Policy template example making use of a named metadata field named `project_path`:

```plaintext
path "secret/data/{{identity.entity.aliases.ACCESSOR_NAME.metadata.project_path}}/staging/*" {
  capabilities = [ "read" ]
}
```

Role example to support the templated policy above, mapping the claim field `project_path`
as a metadata field through use of [`claim_mappings`](https://developer.hashicorp.com/vault/api-docs/auth/jwt#claim_mappings)
configuration:

```plaintext
{
  "role_type": "jwt",
  ...
  "claim_mappings": {
    "project_path": "project_path"
  }
}
```

For the full list of options, see Vault's [Create Role documentation](https://developer.hashicorp.com/vault/api-docs/auth/jwt#create-role).

WARNING:
Always restrict your roles to project or namespace by using one of the provided claims
(for example, `project_id` or `namespace_id`). Otherwise any JWT generated by this instance
may be allowed to authenticate using this role.

Now, configure the JWT Authentication method:

```shell
$ vault write auth/jwt/config \
    oidc_discovery_url="https://gitlab.example.com" \
    bound_issuer="https://gitlab.example.com"
```

[`bound_issuer`](https://developer.hashicorp.com/vault/api-docs/auth/jwt#bound_issuer)
specifies that only a JWT with the issuer (that is, the `iss` claim) set to `gitlab.example.com`
can use this method to authenticate, and that the `oidc_discovery_url` (`https://gitlab.example.com`)
should be used to validate the token.

For the full list of available configuration options, see Vault's [API documentation](https://developer.hashicorp.com/vault/api-docs/auth/jwt#configure).

In GitLab, create the following [CI/CD variables](../variables/_index.md#for-a-project)
to provide details about your Vault server:

- `VAULT_SERVER_URL` - The URL of your Vault server, for example `https://vault.example.com:8200`.
- `VAULT_AUTH_ROLE` - Optional. The role to use when attempting to authenticate. If no role is specified,
  Vault uses the [default role](https://developer.hashicorp.com/vault/api-docs/auth/jwt#default_role)
  specified when the authentication method was configured.
- `VAULT_AUTH_PATH` - Optional. The path where the authentication method is mounted.
  Default is `jwt`.
- `VAULT_NAMESPACE` - Optional. The [Vault Enterprise namespace](https://developer.hashicorp.com/vault/docs/enterprise/namespaces)
  to use for reading secrets and authentication. If no namespace is specified, Vault uses the root (`/`) namespace.
  The setting is ignored by Vault Open Source.

### Automatic ID token authentication with Hashicorp Vault

The following job, when run for the default branch, can read secrets under `secret/myproject/staging/`,
but not the secrets under `secret/myproject/production/`:

```yaml
job_with_secrets:
  id_tokens:
    VAULT_ID_TOKEN:
      aud: https://vault.example.com
  secrets:
    STAGING_DB_PASSWORD:
      vault: secret/myproject/staging/db/password@secrets # authenticates using $VAULT_ID_TOKEN
  script:
    - access-staging-db.sh --token $STAGING_DB_PASSWORD
```

In this example:

- `id_tokens` - The JSON Web Token (JWT) used for OIDC authentication. The `aud` claim
  is set to match the `bound_audiences` parameter of the Vault JWT authentication method.
- `@secrets` - The vault name, where your Secrets Engines are enabled.
- `secret/myproject/staging/db` - The path location of the secret in Vault.
- `password` The field to be fetched in the referenced secret.

If more than one ID token is defined, use the `token` keyword to specify which token should be used. For example:

```yaml
job_with_secrets:
  id_tokens:
    FIRST_ID_TOKEN:
      aud: https://first.service.com
    SECOND_ID_TOKEN:
      aud: https://second.service.com
  secrets:
    FIRST_DB_PASSWORD:
      vault: first/db/password
      token: $FIRST_ID_TOKEN
    SECOND_DB_PASSWORD:
      vault: second/db/password
      token: $SECOND_ID_TOKEN
  script:
    - access-first-db.sh --token $FIRST_DB_PASSWORD
    - access-second-db.sh --token $SECOND_DB_PASSWORD
```

### Manual ID Token authentication

You can use ID tokens to authenticate with HashiCorp Vault manually. For example:

```yaml
manual_authentication:
  variables:
    VAULT_ADDR: http://vault.example.com:8200
  image: vault:latest
  id_tokens:
    VAULT_ID_TOKEN:
      aud: http://vault.example.com
  script:
    - export VAULT_TOKEN="$(vault write -field=token auth/jwt/login role=myproject-example jwt=$VAULT_ID_TOKEN)"
    - export PASSWORD="$(vault kv get -field=password secret/myproject/example/db)"
    - my-authentication-script.sh $VAULT_TOKEN $PASSWORD
```

### Limit token access to Vault secrets

You can control ID token access to Vault secrets by using Vault protections
and GitLab features. For example, restrict the token by:

- Using Vault [bound audiences](https://developer.hashicorp.com/vault/docs/auth/jwt#bound-audiences)
  for specific ID token `aud` claims.
- Using Vault [bound claims](https://developer.hashicorp.com/vault/docs/auth/jwt#bound-claims)
  for specific groups using `group_claim`.
- Hard coding values for Vault bound claims based on the `user_login` and `user_email`
  of specific users.
- Setting Vault time limits for TTL of the token as specified in [`token_explicit_max_ttl`](https://developer.hashicorp.com/vault/api-docs/auth/jwt#token_explicit_max_ttl),
  where the token expires after authentication.
- Scoping the JWT to [GitLab protected branches](../../user/project/repository/branches/protected.md)
  that are restricted to a subset of project users.
- Scoping the JWT to [GitLab protected tags](../../user/project/protected_tags.md),
  that are restricted to a subset of project users.

## Troubleshooting

### `The secrets provider can not be found. Check your CI/CD variables and try again.` message

You might receive this error when attempting to start a job configured to access HashiCorp Vault:

```plaintext
The secrets provider can not be found. Check your CI/CD variables and try again.
```

The job can't be created because the required variable is not defined:

- `VAULT_SERVER_URL`

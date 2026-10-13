---
stage: Software Supply Chain Security
group: Pipeline Security
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: Update your HashiCorp Vault configuration to use ID tokens instead of the deprecated CI_JOB_JWT variables.
title: 'Tutorial: Update HashiCorp Vault configuration to use ID Tokens'
---

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

This tutorial demonstrates how to convert your current CI/CD secrets configuration to use
[ID tokens](id_token_authentication.md).

The `CI_JOB_JWT` variables are deprecated. To use ID tokens instead, you must update your Vault
authentication method and role configuration.

To convert to ID tokens:

1. Update your Vault configuration. Choose one:
   - [Migrate JWT roles to a new auth path](#migrate-jwt-roles-to-a-new-auth-path)
     1. [Create a second JWT authentication path in Vault](#create-a-second-jwt-authentication-path-in-vault)
     1. [Recreate roles to use the new authentication path](#recreate-roles-to-use-the-new-authentication-path)
   - [Move the `iss` claim to role-level claims](#move-the-iss-claim-to-role-level-claims)
     1. [Add `bound_issuers` claim map to each role](#add-bound_issuers-claim-map-to-each-role)
     1. [Remove `bound_issuers` claim from auth method](#remove-bound_issuers-claim-from-auth-method)
1. [Update your CI/CD jobs](#update-your-cicd-jobs)

## Before you begin

This tutorial assumes you are familiar with GitLab CI/CD and Vault.

To follow along, you must have:

- A Vault server you already use.
- CI/CD jobs that retrieve secrets from Vault with `CI_JOB_JWT`.

> [!note]
> In Vault 1.17 and later, [JWT auth login requires bound audiences on the role](https://developer.hashicorp.com/vault/docs/upgrading/upgrade-to-1.17.x#jwt-auth-login-requires-bound-audiences-on-the-role)
> when the JWT contains an `aud` claim. The `aud` claim can be a single string or a list of strings.

## Migrate JWT roles to a new auth path

This approach creates a second JWT auth method in parallel to your current one, then recreates
your roles to use it.
If you'd rather not duplicate your auth method, use
[role-level claims](#move-the-iss-claim-to-role-level-claims) instead.

### Create a second JWT authentication path in Vault

In these examples, replace `gitlab.example.com` with the URL of your GitLab instance.

As part of the transition from `CI_JOB_JWT` to ID tokens, you must update the `bound_issuer` in
Vault to include `https://`:

```shell
$ vault write auth/jwt/config \
    oidc_discovery_url="https://gitlab.example.com" \
    bound_issuer="https://gitlab.example.com"
```

After you make this change, jobs that use `CI_JOB_JWT` start to fail.

To transition to ID tokens on a per-project or per-job basis without disruption, create multiple
authentication paths in Vault:

1. Configure a new authentication path with the name `jwt_v2`, run:

   ```shell
   vault auth enable -path jwt_v2 jwt
   ```

   You can choose a different name, but the rest of these examples assume you used `jwt_v2`, so
   update the examples as needed.

1. Configure the new authentication path for your instance:

   ```shell
   $ vault write auth/jwt_v2/config \
       oidc_discovery_url="https://gitlab.example.com" \
       bound_issuer="https://gitlab.example.com"
   ```

### Recreate roles to use the new authentication path

In these examples, replace `vault.example.com` with the URL of your Vault server.

Roles are bound to a specific authentication path, so you need to add new roles for each job.
The `bound_audiences` parameter for the role is mandatory if the JWT contains an audience, and
must match at least one of the associated `aud` claims of the JWT.

1. Recreate the role for staging named `myproject-staging`:

   ```shell
   $ vault write auth/jwt_v2/role/myproject-staging - <<EOF
   {
     "role_type": "jwt",
     "policies": ["myproject-staging"],
     "token_explicit_max_ttl": 60,
     "user_claim": "user_email",
     "bound_audiences": ["https://vault.example.com"],
     "bound_claims": {
       "project_id": "22",
       "ref": "master",
       "ref_type": "branch"
     }
   }
   EOF
   ```

1. Recreate the role for production named `myproject-production`:

   ```shell
   $ vault write auth/jwt_v2/role/myproject-production - <<EOF
   {
     "role_type": "jwt",
     "policies": ["myproject-production"],
     "token_explicit_max_ttl": 60,
     "user_claim": "user_email",
     "bound_audiences": ["https://vault.example.com"],
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

You only need to update `jwt` to `jwt_v2` in the `vault` command. Do not change the `role_type`
inside the role.

## Move the `iss` claim to role-level claims

This approach doesn't require you to create a second JWT auth method or recreate any roles.
Instead, you add the new `iss` claim value directly to your current roles.
If you'd rather keep a single claim value per role, use a
[new auth path](#migrate-jwt-roles-to-a-new-auth-path) instead.

### Add `bound_issuers` claim map to each role

In these examples, replace `gitlab.example.com` with the URL of your GitLab instance,
`vault.example.com` with the URL of your Vault server, and `jwt` with your current auth method
name.

Vault doesn't allow multiple `iss` claims on the JWT auth method level, as the
[`bound_issuer`](https://developer.hashicorp.com/vault/api-docs/auth/jwt#bound_issuer) directive
on this level only accepts a single value. However, you can configure multiple claims on the role
level with the [`bound_claims`](https://developer.hashicorp.com/vault/api-docs/auth/jwt#bound_claims)
map configuration directive.

With this approach, you give Vault multiple options for the `iss` claim validation: the `https://`
prefixed GitLab instance hostname claim that comes with ID tokens, and the old non-prefixed claim.

To add the [`bound_claims`](https://developer.hashicorp.com/vault/api-docs/auth/jwt#bound_claims)
configuration to the required roles, run:

```shell
$ vault write auth/jwt/role/myproject-staging - <<EOF
{
  "role_type": "jwt",
  "policies": ["myproject-staging"],
  "token_explicit_max_ttl": 60,
  "user_claim": "user_email",
  "bound_audiences": ["https://vault.example.com"],
  "bound_claims": {
    "iss": [
      "https://gitlab.example.com",
      "gitlab.example.com"
    ],
    "project_id": "22",
    "ref": "master",
    "ref_type": "branch"
  }
}
EOF
```

You do not need to alter any current role configurations except for the `bound_claims` section.
Make sure to add the `iss` configuration as shown previously, to ensure Vault accepts the
prefixed and non-prefixed `iss` claim for this role.

You must apply this change to all JWT roles used for the GitLab integration before you continue to
the next step.

### Remove `bound_issuers` claim from auth method

After all roles have been updated with the `bound_claims.iss` claims, you can remove the auth
method level configuration for this validation:

```shell
$ vault write auth/jwt/config \
    oidc_discovery_url="https://gitlab.example.com" \
    bound_issuer=""
```

An empty `bound_issuer` value removes the issuer validation on the auth method level. However,
because this validation is now at the role level, the configuration is still secure.

Once you've migrated every project to ID tokens and no longer need to support `CI_JOB_JWT` in
parallel, you can revert this configuration: remove the `iss` claim from `bound_claims` in each
role, and set `bound_issuer` back to a single value on the auth method.

## Update your CI/CD jobs

Vault has two different [KV Secrets Engines](https://developer.hashicorp.com/vault/docs/secrets/kv).
The version you use impacts how you define secrets in CI/CD.

Check the [Which Version is my Vault KV Mount?](https://support.hashicorp.com/hc/en-us/articles/4404288741139-Which-Version-is-my-Vault-KV-Mount)
article on HashiCorp's support portal to check your Vault server.

Also, if needed you can review the CI/CD documentation for:

- [`secrets:`](../yaml/_index.md#secrets)
- [`id_tokens:`](../yaml/_index.md#id_tokens)

These examples show how to obtain the staging database password. It's stored in the `password`
field of `secret/myproject/staging/db`. In these examples, replace `vault.example.com` with the
URL of your Vault server.

The value for the `VAULT_AUTH_PATH` variable depends on which approach you used to migrate:

- New auth path: Use `jwt_v2`.
- Role-level claims: Use `jwt`.

### KV Secrets Engine v1

The [`secrets:vault`](../yaml/_index.md#secretsvault) keyword defaults to v2 of the KV Mount, so
you need to explicitly configure the job to use the v1 engine:

```yaml
job:
  variables:
    VAULT_SERVER_URL: https://vault.example.com
    VAULT_AUTH_PATH: jwt_v2  # or "jwt" if you used the role-level claims approach
    VAULT_AUTH_ROLE: myproject-staging
  id_tokens:
    VAULT_ID_TOKEN:
      aud: https://vault.example.com
  secrets:
    PASSWORD:
      vault:
        engine:
          name: kv-v1
          path: secret
        field: password
        path: myproject/staging/db
      file: false
```

Both `VAULT_SERVER_URL` and `VAULT_AUTH_PATH` can be
[defined as project or group CI/CD variables](../variables/_index.md#define-a-cicd-variable-in-the-ui),
if preferred.

[`secrets:file`](../yaml/_index.md#secretsfile) is set to `false` because ID tokens place secrets
in a file by default. The secret needs to work as a regular variable instead, to match the old
behavior.

### KV Secrets Engine v2

You can use two formats for the v2 engine.

Long format:

```yaml
job:
  variables:
    VAULT_SERVER_URL: https://vault.example.com
    VAULT_AUTH_PATH: jwt_v2  # or "jwt" if you used the role-level claims approach
    VAULT_AUTH_ROLE: myproject-staging
  id_tokens:
    VAULT_ID_TOKEN:
      aud: https://vault.example.com
  secrets:
    PASSWORD:
      vault:
        engine:
          name: kv-v2
          path: secret
        field: password
        path: myproject/staging/db
      file: false
```

This long format is the same as the example for the v1 engine, but `secrets:vault:engine:name:` is
set to `kv-v2` to match the engine.

You can also use a short format:

```yaml
job:
  variables:
    VAULT_SERVER_URL: https://vault.example.com
    VAULT_AUTH_PATH: jwt_v2  # or "jwt" if you used the role-level claims approach
    VAULT_AUTH_ROLE: myproject-staging
  id_tokens:
    VAULT_ID_TOKEN:
      aud: https://vault.example.com
  secrets:
      PASSWORD:
        vault: myproject/staging/db/password@secret
        file: false
```

After you commit the updated CI/CD configuration, your jobs fetch secrets with ID tokens.
Congratulations!

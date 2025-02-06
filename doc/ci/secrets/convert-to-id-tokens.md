---
stage: Software Supply Chain Security
group: Pipeline Security
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: 'Tutorial: Update HashiCorp Vault configuration to use ID Tokens'
---

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

NOTE:
Starting in Vault 1.17, [JWT auth login requires bound audiences on the role](https://developer.hashicorp.com/vault/docs/upgrading/upgrade-to-1.17.x#jwt-auth-login-requires-bound-audiences-on-the-role)
when the JWT contains an `aud` claim. The `aud` claim can be a single string or a list of strings.

This tutorial demonstrates how to convert your existing CI/CD secrets configuration to use [ID Tokens](../secrets/id_token_authentication.md).

The `CI_JOB_JWT` variables are deprecated, but updating to ID tokens requires some
important configuration changes to work with Vault. If you have more than a handful of jobs,
converting everything at once is a daunting task.

There isn't one standard method to migrate to [ID tokens](../secrets/id_token_authentication.md), so this tutorial
includes two variations for how to convert your existing CI/CD secrets. Choose the method that is most appropriate for
your use case:

1. Update your Vault configuration:
   - Method A: Migrate JWT roles to the new Vault auth method
     1. [Create a second JWT authentication path in Vault](#create-a-second-jwt-authentication-path-in-vault)
     1. [Recreate roles to use the new authentication path](#recreate-roles-to-use-the-new-authentication-path)
   - Method B: Move `iss` claim to roles for the migration window
     1. [Add `bound_issuers` claim map to each role](#add-bound_issuers-claim-map-to-each-role)
     1. [Remove `bound_issuers` claim from auth method](#remove-bound_issuers-claim-from-auth-method)
1. [Update your CI/CD Jobs](#update-your-cicd-jobs)

## Prerequisites

This tutorial assumes you are familiar with GitLab CI/CD and Vault.

To follow along, you must have:

- An instance running GitLab 16.0 or later, or be on GitLab.com.
- A Vault server that you are already using.
- CI/CD jobs retrieving secrets from Vault with `CI_JOB_JWT`.

In the examples below, replace:

- `vault.example.com` with the URL of your Vault server.
- `gitlab.example.com` with the URL of your GitLab instance.
- `jwt` or `jwt_v2` with your auth method names.

## Method A: Migrate JWT roles to the new Vault auth method

This method creates a second JWT auth method in parallel to the existing one in use. Afterwards all Vault roles used for the GitLab integration are recreated in this new auth method.

### Create a second JWT authentication path in Vault

As part of the transition from `CI_JOB_JWT` to ID tokens, you must update the `bound_issuer` in Vault to include `https://`:

```shell
$ vault write auth/jwt/config \
    oidc_discovery_url="https://gitlab.example.com" \
    bound_issuer="https://gitlab.example.com"
```

After you make this change, jobs that use `CI_JOB_JWT` start to fail.

You can create multiple authentication paths in Vault, which enable you to transition to ID Tokens on a project by job basis without disruption.

1. Configure a new authentication path with the name `jwt_v2`, run:

   ```shell
   vault auth enable -path jwt_v2 jwt
   ```

   You can choose a different name, but the rest of these examples assume you used `jwt_v2`, so update the examples as needed.

1. Configure the new authentication path for your instance:

   ```shell
   $ vault write auth/jwt_v2/config \
       oidc_discovery_url="https://gitlab.example.com" \
       bound_issuer="https://gitlab.example.com"
   ```

### Recreate roles to use the new authentication path

Roles are bound to a specific authentication path so you need to add new roles for each job.
The `bound_audiences` parameter for the role is mandatory if the JWT contains an
audience and must match at least one of the associated `aud` claims of the JWT.

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

You only need to update `jwt` to `jwt_v2` in the `vault` command, do not change the `role_type` inside the role.

## Method B: Move `iss` claim to roles for migration window

This method doesn't require Vault administrators to create a second JWT auth method and recreate all GitLab related roles.

### Add `bound_issuers` claim map to each role

Vault doesn't allow multiple `iss` claims on the JWT auth method level, as the [`bound_issuer`](https://developer.hashicorp.com/vault/api-docs/auth/jwt#bound_issuer)
directive on this level only accepts a single value. However, multiple claims can be configured
on the role level by using the [`bound_claims`](https://developer.hashicorp.com/vault/api-docs/auth/jwt#bound_claims)
map configuration directive.

With this method you can provide Vault with multiple options for the `iss` claim validation. This supports the `https://` prefixed GitLab instance hostname claim that comes with the `id_tokens`, as well as the old non-prefixed claim.

To add the [`bound_claims`](https://developer.hashicorp.com/vault/api-docs/auth/jwt#bound_claims) configuration to the required roles, run:

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

You do not need to alter any existing role configurations except for the `bound_claims` section
Make sure to add the `iss` configuration as shown above to ensure Vault accepts
the prefixed and non-prefixed `iss` claim for this role.

You must apply this change to all JWT roles used for the GitLab integration before moving on to the next step.

You can revert the migration of the `iss` claim validation from the auth method to the roles if desired,
after all projects have been migrated and you no longer need parallel support for `CI_JOB_JWT` and ID tokens.

### Remove `bound_issuers` claim from auth method

After all roles have been updated with the `bound_claims.iss` claims, you can remove the auth method level configuration for this validation:

```shell
$ vault write auth/jwt/config \
    oidc_discovery_url="https://gitlab.example.com" \
    bound_issuer=""
```

Setting the `bound_issuer` directive to an empty string removes the issuer validation on the auth method level.
However, as we have moved this validation to the role level, this configuration is still secure.

## Update your CI/CD Jobs

Vault has two different [KV Secrets Engines](https://developer.hashicorp.com/vault/docs/secrets/kv) and the version you are using impacts how you define secrets in CI/CD.

Check the [Which Version is my Vault KV Mount?](https://support.hashicorp.com/hc/en-us/articles/4404288741139-Which-Version-is-my-Vault-KV-Mount) article on HashiCorp's support portal to check your Vault server.

Also, if needed you can review the CI/CD documentation for:

- [`secrets:`](../yaml/_index.md#secrets)
- [`id_tokens:`](../yaml/_index.md#id_tokens)

The following examples show how to obtain the staging database password written to the `password` field in `secret/myproject/staging/db`.

The value for the `VAULT_AUTH_PATH` variable depends on the migration method you used:

- Method A (Migrate JWT roles to the new Vault auth method): Use `jwt_v2`.
- Method B (Move `iss` claim to roles for migration window): Use `jwt`.

### KV Secrets Engine v1

The [`secrets:vault`](../yaml/_index.md#secretsvault) keyword defaults to v2 of the KV Mount, so you need to explicitly configure the job to use the v1 engine:

```yaml
job:
  variables:
    VAULT_SERVER_URL: https://vault.example.com
    VAULT_AUTH_PATH: jwt_v2  # or "jwt" if you used method B
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

Both `VAULT_SERVER_URL` and `VAULT_AUTH_PATH` can be [defined as project or group CI/CD variables](../variables/_index.md#define-a-cicd-variable-in-the-ui),
if preferred.

We use [`secrets:file:false`](../yaml/_index.md#secretsfile) because ID tokens place secrets in a file by default, but we need it to work as a regular variable to match the old behavior.

### KV Secrets Engine v2

There are two formats you can use for the v2 engine.

Long format:

```yaml
job:
  variables:
    VAULT_SERVER_URL: https://vault.example.com
    VAULT_AUTH_PATH: jwt_v2  # or "jwt" if you used method B
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

This is the same as the example for the v1 engine but `secrets:vault:engine:name:` is set to `kv-v2` to match the engine.

You can also use a short format:

```yaml
job:
  variables:
    VAULT_SERVER_URL: https://vault.example.com
    VAULT_AUTH_PATH: jwt_v2  # or "jwt" if you used method B
    VAULT_AUTH_ROLE: myproject-staging
  id_tokens:
    VAULT_ID_TOKEN:
      aud: https://vault.example.com
  secrets:
      PASSWORD:
        vault: myproject/staging/db/password@secret
        file: false
```

After you commit the updated CI/CD configuration, your jobs will be fetching secrets with ID Tokens, congratulations!

If you have migrated all projects to fetch secrets with ID Tokens and used method B for the migration, it is now possible to move the `iss` claim validation back to the auth method configuration if you desire.

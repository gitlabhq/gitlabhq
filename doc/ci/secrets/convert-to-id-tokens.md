---
stage: Verify
group: Pipeline Security
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
type: tutorial
---

# Tutorial: Update HashiCorp Vault configuration to use ID Tokens **(PREMIUM)**

This tutorial demonstrates how to convert your existing CI/CI secrets configuration to use [ID Tokens](../secrets/id_token_authentication.md).

The `CI_JOB_JWT` variables are deprecated, but updating to ID tokens requires some important configuration changes to work with Vault. If you have more than a handful of jobs, converting everything at once is a daunting task.

From GitLab 15.9 to 15.11, [enable the automatic ID token authentication](../secrets/id_token_authentication.md#enable-automatic-id-token-authentication-deprecated)
setting to enable ID Tokens and disable `CI_JOB_JWT` tokens.

In GitLab 16.0 and later you can use ID tokens without any settings changes.
Jobs that use `secrets:vault` automatically do not have `CI_JOB_JWT` tokens available,
Jobs that don't use `secrets:vault` can still use `CI_JOB_JWT` tokens.

This tutorial will focus on v16 onwards, if you are running a slightly older version you will need to toggle the `Limit JSON Web Token (JWT) access` setting as appropriate.

To update your vault configuration to use ID tokens:

1. [Create a second JWT authentication path in Vault](#create-a-second-jwt-authentication-path-in-vault)
1. [Recreate roles to use the new authentication path](#recreate-roles-to-use-the-new-authentication-path)
1. [Update your CI/CD Jobs](#update-your-cicd-jobs)

## Prerequisites

This tutorial assumes you are familiar with GitLab CI/CD and Vault.

To follow along, you must have:

- An instance running GitLab 15.9 or later, or be on GitLab.com.
- A Vault server that you are already using.
- CI/CD jobs retrieving secrets from Vault with `CI_JOB_JWT`.

In the examples below, replace `vault.example.com` with the URL of your Vault server,
and `gitlab.example.com` with the URL of your GitLab instance.

## Create a second JWT authentication path in Vault

As part of the transition from `CI_JOB_JWT` to ID tokens, you must update the `bound_issuer` in Vault to include `https://`:

```shell
$ vault write auth/jwt/config \
    jwks_url="https://gitlab.example.com/-/jwks" \
    bound_issuer="https://gitlab.example.com"
```

After you make this change, jobs that use `CI_JOB_JWT` start to fail.

You can create multiple authentication paths in Vault, which enable you to transition to IT Tokens on a project by job basis without disruption.

1. Configure a new authentication path with the name `jwt_v2`, run:

   ```shell
   vault auth enable -path jwt_v2 jwt
   ```

   You can choose a different name, but the rest of these examples assume you used `jwt_v2`, so update the examples as needed.

1. Configure the new authentication path for your instance:

   ```shell
   $ vault write auth/jwt_v2/config \
       jwks_url="https://gitlab.example.com/-/jwks" \
       bound_issuer="https://gitlab.example.com"
   ```

## Recreate roles to use the new authentication path

Roles are bound to a specific authentication path so you need to add new roles for each job.

1. Recreate the role for staging named `myproject-staging`:

   ```shell
   $ vault write auth/jwt_v2/role/myproject-staging - <<EOF
   {
     "role_type": "jwt",
     "policies": ["myproject-staging"],
     "token_explicit_max_ttl": 60,
     "user_claim": "user_email",
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

## Update your CI/CD Jobs

Vault has two different [KV Secrets Engines](https://developer.hashicorp.com/vault/docs/secrets/kv) and the version you are using impacts how you define secrets in CI/CD.

Check the [Which Version is my Vault KV Mount?](https://support.hashicorp.com/hc/en-us/articles/4404288741139-Which-Version-is-my-Vault-KV-Mount-) article on HashiCorp's support portal to check your Vault server.

Also, if needed you can review the CI/CD documentation for:

- [`secrets:`](../yaml/index.md#secrets)
- [`id_tokens:`](../yaml/index.md#id_tokens)

The following examples show how to obtain the staging database password written to the `password` field in `secret/myproject/staging/db`

### KV Secrets Engine v1

The [`secrets:vault`](../yaml/index.md#secretsvault) keyword defaults to v2 of the KV Mount, so you need to explicitly configure the job to use the v1 engine:

```yaml
job:
  variables:
    VAULT_SERVER_URL: https://vault.example.com
    VAULT_AUTH_PATH: jwt_v2
    VAULT_AUTH_ROLE: myproject-staging
  id_tokens:
    VAULT_ID_TOKEN:
      aud: https://gitlab.example.com
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

Both `VAULT_SERVER_URL` and `VAULT_AUTH_PATH` can be [defined as project or group CI/CD variables](../../ci/variables/index.md#define-a-cicd-variable-in-the-ui),
if preferred.

We use [`secrets:file:false`](../../ci/yaml/index.md#secretsfile) because ID tokens place secrets in a file by default, but we need it to work as a regular variable to match the old behavior.

### KV Secrets Engine v2

There are two formats you can use for the v2 engine.

Long format:

```yaml
job:
  variables:
    VAULT_SERVER_URL: https://vault.example.com
    VAULT_AUTH_PATH: jwt_v2
    VAULT_AUTH_ROLE: myproject-staging
  id_tokens:
    VAULT_ID_TOKEN:
      aud: https://gitlab.example.com
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
    VAULT_AUTH_PATH: jwt_v2
    VAULT_AUTH_ROLE: myproject-staging
  id_tokens:
    VAULT_ID_TOKEN:
      aud: https://gitlab.example.com
  secrets:
      PASSWORD:
        vault: myproject/staging/db/password@secret
        file: false
```

After you commit the updated CI/CD configuration, your jobs will be fetching secrets with ID Tokens, congratulations!

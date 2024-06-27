---
owning-stage: "~devops::verify"
description: 'Use case study: using secrets in a CI job'
---

# Use case study: using secrets in a CI job

## Objectives

- To map out how users can use their native GitLab secrets in their CI jobs.
- Given OpenBao is a fork of HashiCorp Vault, we want to confirm its compatibility with our [Vault integration in Runner](../../../../ci/secrets/index.md).
- At a high level, gain a better understanding of how to structure OpenBao [policies](https://openbao.org/docs/concepts/policies/) and [JWT roles](https://openbao.org/docs/auth/jwt/#configuration) to be compatible with a project's varied permissions per GitLab user role.

## Prerequisites

The workflow requires that the [templated policies](https://openbao.org/docs/concepts/policies/#templated-policies) for each combination of [capabilities](https://openbao.org/docs/concepts/policies/#capabilities) (e.g. `read+update`, `read+update+create`) are predefined. For example, consider the following templated policy that allows full access to a project's secrets:

```shell
bao policy write project_full_access - <<EOF
path "kv-v2/data/projects/{{identity.entity.aliases.auth_jwt_02163755.metadata.project_id}}/*" {
  capabilities = [ "read", "create", "update", "delete", "list" ]
}
EOF
```

The policies are associated to JWT roles on authorization. The `project_full_access` policy is particularly important for the initial project owner role:

```shell
bao write auth/jwt/role/project_owner - <<EOF
{
  "role_type": "jwt",
  "policies": ["project_full_access"],
  "token_explicit_max_ttl": 60,
  "user_claim": "user_id",
  "claim_mappings": {
    "project_id": "project_id"
  },
  "bound_audiences": "secrets.gitlab.com",
  "bound_claims_type": "glob",
  "bound_claims": {
    "user_access_level": "owner"
  }
}
EOF
```

Given OpenBao policies are deny by default, this initial JWT role is necessary to grant project owners full access to read and write secrets.

## Initial setup workflow

Details the steps and technical information for when the project's native secrets are set up for the first time.

1. Project owner enables GitLab Secrets manager through the GitLab UI.
1. Project owner defines additional permissions on which GitLab user roles can read, write, or create secrets through the GitLab UI.
   - By default, project owners have full access and other roles are denied.
   - For example, if the owner allows read-only access for `developer` role then, through the OpenBao API, the Rails backend defines `project_88_developer`:

     ```shell
     # The format of the role name is `project_<project-id>_<user-role>`
     bao write auth/jwt/role/project_88_developer - <<EOF
      {
        "role_type": "jwt",
        "policies": ["project_read_only"],
        "token_explicit_max_ttl": 60,
        "user_claim": "user_id",
        "claim_mappings": {
          "project_id": "project_id"
        },
        "bound_audiences": "secrets.gitlab.com",
        "bound_claims_type": "glob",
        "bound_claims": {
          "user_access_level": "developer"
        }
      }
      EOF
     ```

   - Unlike the `project_owner` generic role, we have to define other non-owner roles tied to the project because projects may have different combinations of permissions per user role.
1. Project owner defines secrets through the GitLab UI.
   - User defines details such as name, key, and value. Sample input:
     - name: `Production Database Password`
     - key: `DB_PASS`
     - value: `mydbpass`
   - The secret is stored in OpenBao under `kv-v2/data/projects/88/ci/DB_PASS`, with the JSON data:

     ```json
     {
       "data": "mydbpass"
     }
     ```

   - The user doesn't need to enter the secret value in JSON format. The Rails backend transforms the input into JSON object with the `data` key before sending it to OpenBao.
1. Developer uses the `secrets` keyword in the `.gitlab-ci.yml`.
   - Sample configuration:

     ```yaml
     job-with-secrets:
       secrets:
         MY_SECRET_ON_OPENBAO:
           key: DB_PASS # Translates to kv-v2/data/projects/88/DB_PASS, field `data`
     ```

   - There is no need to specify `id_tokens:VAULT_ID_TOKEN` as `aud` defaults to `https://secrets.gitlab.com` where OpenBao service is.
   - Unlike with HashiCorp Vault, there is no need to define CI/CD variables.
     - The `VAULT_SERVER_URL` defaults to `https://secrets.gitlab.com` where OpenBao service is.
     - The `VAULT_AUTH_ROLE` defaults to `project_<project_id>_<job_user_role>` to match the JWT role in OpenBao.
1. The CI job runs and `MY_SECRET_ON_OPENBAO` is available as an environment variable.
   - OpenBao verifies the integrity of the ID token and validates the `bound_claims` if it matches the custom claims, specially the `user_access_level` which contains the GitLab user role of the user.
   - Similar to HashiCorp Vault secrets, this is a [`file` variable](../../../../ci/variables/index.md#use-file-type-cicd-variables).

## Technical implementation findings

High-level technical implementation details pertaining to OpenBao and Rails to support the workflow.

1. The OpenBao service needs to be properly configured to make it compatible with the workflow.
   - Configure [JWT authentication](https://openbao.org/docs/auth/jwt/#jwt-authentication) to make it work with [ID tokens authentication](../../../../ci/secrets/id_token_authentication.md#automatic-id-token-authentication-with-hashicorp-vault).
   - The documentation shows [instructions](../../../../ci/secrets/index.md#configure-your-vault-server) using the `vault` CLI, but it should work similarly for `bao`.
   - The OpenBao API is reachable through `https://secrets.gitlab.com`.
   - To reference the `project_id` in the templated policy, it was needed to get the value of the JWT auth mount accessor (`auth_jwt_02163755` from the result of `bao auth list`). This has to be automated during deployments so that the templated policies remain up-to-date with the correct accessor. The mount accessor value is persisted in storage and keeps its value even when the OpenBao server is restarted and sealed.
1. The Rails backend needs the accompanying implementations to support the workflow.
   - ActiveRecord model for the secrets. Listing secrets and viewing details in the UI shouldn't make a request to OpenBao.
   - ActiveRecord model for the permissions. Listing permissions in the UI shouldn't make a request to OpenBao.
   - Update ID tokens related implementation to support the use of ID tokens without the need to define `id_tokens` in the CI configuration.
   - Proper mapping of defaults for `VAULT_SERVER_URL` and `VAULT_AUTH_ROLE`.

## How to test locally

The policies and roles structure presented here was first tested locally on a GDK setup and OpenBao server running on [`dev` mode](https://openbao.org/docs/get-started/developer-qs/).

Here's a step-by-step guide on how to test this locally:

1. Make sure [GDK is properly set up with runner](https://gitlab.com/gitlab-org/gitlab-development-kit/blob/main/doc/howto/runner.md).
   - Tested on a [GDK with Docker executor](https://gitlab.com/gitlab-org/gitlab-development-kit/blob/main/doc/howto/runner.md#set-up-a-local-network) and pointed `gdk.test` to `172.16.123.1` but this should also work with a shell executor.
   - Confirm that you can successfully run a CI pipeline on a test project.
1. Create the test project for fetching the secrets from OpenBao later.
   - Track its project ID. In this example, the project ID was `53`.
1. Start-up the OpenBao in [`dev` mode](https://openbao.org/docs/concepts/dev-server/).

   ```shell
   bao server -dev -dev-root-token-id="dev-only-token"
   ```

   - This makes OpenBao reachable at `http://127.0.0.1:8200`.
   - You might need to run `export BAO_ADDR='http://127.0.0.1:8200'` for the `bao` CLI commands below to work.
1. Enable kv-v2 secrets engine.

   ```shell
   bao secrets enable kv-v2 # By default mounts to `kv-v2/data`
   ```

1. Enable jwt authentication.

   ```shell
   bao auth enable jwt
   ```

1. Configure OpenBao JWT authentication.

   ```shell
   bao write auth/jwt/config \
     oidc_discovery_url="http://gdk.test:3000" \
     bound_issuer="http://gdk.test:3000"
   ```

1. To test the policy and role generated for a project owner with the GitLab user role `owner`, create the [templated policy](https://openbao.org/docs/concepts/policies/#templated-policies) and the JWT role for the specific `owner` role. The JWT role was based on the [GitLab Vault sample server role](../../../../ci/secrets/index.md#configure-vault-server-roles).
   - Take note of the value of the JWT auth mount accessor when you run `bao auth list`:

     ```shell
     Path      Type     Accessor               Description                Version
     ----      ----     --------               -----------                -------
     jwt/      jwt      auth_jwt_02163755      n/a                        n/a
     token/    token    auth_token_90d6d0c1    token based credentials    n/a
     ```

   - define the templated policy and reference the `project_id` through the metadata of the mounted JWT auth plugin:

     ```shell
     bao policy write project_full_access - <<EOF

     # owners have full read-write access to their project's secrets
     # copy over the `auth_jwt_02163755` mount accessor value
     path "kv-v2/data/projects/{{identity.entity.aliases.auth_jwt_02163755.metadata.project_id}}/*" {
       capabilities = [ "read", "create", "update", "delete", "list" ]
     }
     EOF
     ```

   - define the JWT role and associate the `project_full_access` policy:

     ```shell
     bao write auth/jwt/role/project_owner - <<EOF
     {
       "role_type": "jwt",
       "policies": ["project_full_access"],
       "token_explicit_max_ttl": 60,
       "user_claim": "user_id",
       "claim_mappings": {
         "project_id": "project_id"
       },
       "bound_audiences": "secrets.gitlab.com",
       "bound_claims_type": "glob",
       "bound_claims": {
         "user_access_level": "owner"
       }
     }
     EOF
     ```

1. Create a sample secret that we want to fetch in the CI job.

   ```shell
   bao kv put -mount=kv-v2 projects/53/foo val=my-long-passcode
   ```

1. On the test project, configure the `.gitlab-ci.yml` to fetch secrets from OpenBao using the existing [Vault integration](../../../../ci/secrets/index.md#use-vault-secrets-in-a-ci-job).

   ```yaml
   test_openbao:
     variables:
       VAULT_SERVER_URL: http://127.0.0.1:8200
       VAULT_AUTH_ROLE: project_owner
     id_tokens:
       VAULT_ID_TOKEN:
       aud: secrets.gitlab.com
     secrets:
       SECRET:
         vault: projects/53/foo/val  # translates to secret `kv-v2/data/projects/53/foo`, field `val`
         token: $VAULT_ID_TOKEN
     script:
       - echo "testing..."
       - cat $SECRET
       - echo "done."
   ```

   - `VAULT_AUTH_ROLE` matches the JWT role we created earlier.
   - `aud` matches the role's `bound_audiences`.
   - The ID token generated in this job is matched by OpenBao using the `bound_claims`, specifically the `user_access_level` which is included in the [custom claims](../../../../ci/secrets/id_token_authentication.md#token-payload) of the ID token.
1. Run a pipeline and confirm that in the job trace there's a masked output of the secret that it fetched from OpenBao.

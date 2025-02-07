---
stage: Software Supply Chain Security
group: Pipeline Security
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Using external secrets in CI
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

Secrets represent sensitive information your CI job needs to complete work. This
sensitive information can be items like API tokens, database credentials, or private keys.
Secrets are sourced from your secrets provider.

Unlike CI/CD variables, which are always presented to a job, secrets must be explicitly
required by a job. Read [GitLab CI/CD pipeline configuration reference](../yaml/_index.md#secrets)
for more information about the syntax.

GitLab provides support for the following secret management providers:

1. [Vault by HashiCorp](#use-vault-secrets-in-a-ci-job)
1. [Google Cloud Secret Manager](gcp_secret_manager.md)
1. [Azure Key Vault](azure_key_vault.md)

GitLab has selected [Vault by HashiCorp](https://www.vaultproject.io) as the
first supported provider, and [KV-V2](https://developer.hashicorp.com/vault/docs/secrets/kv/kv-v2)
as the first supported secrets engine.

Use [ID tokens](../yaml/_index.md#id_tokens) to [authenticate with Vault](https://developer.hashicorp.com/vault/docs/auth/jwt#jwt-authentication).
The [Authenticating and Reading Secrets With HashiCorp Vault](hashicorp_vault.md)
tutorial has more details about authenticating with ID tokens.

You must [configure your Vault server](#configure-your-vault-server) before you
can [use Vault secrets in a CI job](#use-vault-secrets-in-a-ci-job).

The flow for using GitLab with HashiCorp Vault
is summarized by this diagram:

![Flow between GitLab and HashiCorp](../img/gitlab_vault_workflow_v13_4.png "How GitLab authenticates with HashiCorp Vault")

1. Configure your vault and secrets.
1. Generate your JWT and provide it to your CI job.
1. Runner contacts HashiCorp Vault and authenticates using the JWT.
1. HashiCorp Vault verifies the JWT.
1. HashiCorp Vault checks the bounded claims and attaches policies.
1. HashiCorp Vault returns the token.
1. Runner reads secrets from the HashiCorp Vault.

NOTE:
Read the [Authenticating and Reading Secrets With HashiCorp Vault](hashicorp_vault.md)
tutorial for a version of this feature. It's available to all
subscription levels, supports writing secrets to and deleting secrets from Vault,
and supports multiple secrets engines.

You must replace the `vault.example.com` URL below with the URL of your Vault server, and `gitlab.example.com` with the URL of your GitLab instance.

## Vault Secrets Engines

> - `generic` option [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/366492) in GitLab Runner 16.11.

The Vault Secrets Engines supported by GitLab Runner are:

| Secrets engine                                                                                                                                     | [`secrets:engine:name`](../yaml/_index.md#secretsvault) value | Runner version | Details |
|----------------------------------------------------------------------------------------------------------------------------------------------------|--------------------------------------------------------------|----------------|---------|
| [KV secrets engine - version 2](https://developer.hashicorp.com/vault/docs/secrets/kv/kv-v2)                                                       | `kv-v2`                                                      | 13.4           | `kv-v2` is the default engine GitLab Runner uses when no engine type is explicitly specified. |
| [KV secrets engine - version 1](https://developer.hashicorp.com/vault/docs/secrets/kv/kv-v1)                                                       | `kv-v1` or `generic`                                         | 13.4           | Support for the `generic` keyword [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/366492) in GitLab 15.11. |
| [The AWS secrets engine](https://developer.hashicorp.com/vault/docs/secrets/aws)                                                                   | `generic`                                                    | 16.11          |         |
| [Hashicorp Vault Artifactory Secrets Plugin](https://jfrog.com/help/r/jfrog-integrations-documentation/hashicorp-vault-artifactory-secrets-plugin) | `generic`                                                    | 16.11          | This secrets backend talks to JFrog Artifactory server (5.0.0 or later) and dynamically provisions access tokens with specified scopes. |

## Configure your Vault server

To configure your Vault server:

1. Ensure your Vault server is running on version 1.2.0 or later.
1. Enable the authentication method by running these commands. They provide your Vault
   server the [OIDC Discovery URL](https://openid.net/specs/openid-connect-discovery-1_0.html) for your GitLab instance, so Vault
   can fetch the public signing key and verify the JSON Web Token (JWT) when authenticating:

   ```shell
   $ vault auth enable jwt

   $ vault write auth/jwt/config \
     oidc_discovery_url="https://gitlab.example.com" \
     bound_issuer="gitlab.example.com"
   ```

1. Configure policies on your Vault server to grant or forbid access to certain
   paths and operations. This example grants read access to the set of secrets
   required by your production environment:

   ```shell
   vault policy write myproject-production - <<EOF
   # Read-only permission on 'ops/data/production/*' path

   path "ops/data/production/*" {
     capabilities = [ "read" ]
   }
   EOF
   ```

1. Configure roles on your Vault server, restricting roles to a project or namespace,
   as described in [Configure Vault server roles](#configure-vault-server-roles) on this page.
1. [Create the following CI/CD variables](../variables/_index.md#for-a-project)
   to provide details about your Vault server:
   - `VAULT_SERVER_URL` - The URL of your Vault server, such as `https://vault.example.com:8200`.
     Required.
   - `VAULT_AUTH_ROLE` - Optional. The role to use when attempting to authenticate.
     If no role is specified, Vault uses the [default role](https://developer.hashicorp.com/vault/api-docs/auth/jwt#default_role)
     specified when the authentication method was configured.
   - `VAULT_AUTH_PATH` - Optional. The path where the authentication method is mounted, default is `jwt`.
   - `VAULT_NAMESPACE` - Optional. The [Vault Enterprise namespace](https://developer.hashicorp.com/vault/docs/enterprise/namespaces)
     to use for reading secrets and authentication. With:
     - Vault, the `root` ("`/`") namespace is used when no namespace is specified.
     - Vault Open source, the setting is ignored.
     - [HashiCorp Cloud Platform (HCP)](https://www.hashicorp.com/cloud) Vault, a namespace
       is required. HCP Vault uses the `admin` namespace as the root namespace by default.
       For example, `VAULT_NAMESPACE=admin`.

   NOTE:
   Support for providing these values in the user interface [is tracked in this issue](https://gitlab.com/gitlab-org/gitlab/-/issues/218677).

## Use Vault secrets in a CI job

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

After [configuring your Vault server](#configure-your-vault-server), you can use
the secrets stored in Vault by defining them with the [`vault` keyword](../yaml/_index.md#secretsvault):

```yaml
job_using_vault:
  id_tokens:
    VAULT_ID_TOKEN:
      aud: https://vault.example.com
  secrets:
    DATABASE_PASSWORD:
      vault: production/db/password@ops  # translates to secret `ops/data/production/db`, field `password`
      token: $VAULT_ID_TOKEN
```

In this example:

- `production/db` - The secret.
- `password` The field.
- `ops` - The path where the secrets engine is mounted.

After GitLab fetches the secret from Vault, the value is saved in a temporary file.
The path to this file is stored in a CI/CD variable named `DATABASE_PASSWORD`,
similar to [variables of type `file`](../variables/_index.md#use-file-type-cicd-variables).

To overwrite the default behavior, set the `file` option explicitly:

```yaml
secrets:
  id_tokens:
    VAULT_ID_TOKEN:
      aud: https://vault.example.com
  DATABASE_PASSWORD:
    vault: production/db/password@ops
    file: false
    token: $VAULT_ID_TOKEN
```

In this example, the secret value is put directly in the `DATABASE_PASSWORD` variable
instead of pointing to a file that holds it.

## Use a different secrets engine

The `kv-v2` secrets engine is used by default. To use [a different engine](#vault-secrets-engines), add an `engine` section
under `vault` in the configuration.

For example, to set the secret engine and path for Artifactory:

```yaml
job_using_vault:
  id_tokens:
    VAULT_ID_TOKEN:
      aud: https://vault.example.com
  secrets:
    JFROG_TOKEN:
      vault:
        engine:
          name: generic
          path: artifactory
        path: production/jfrog
        field: access_token
      file: false
```

In this example, the secret value is obtained from `artifactory/production/jfrog` with a field of `access_token`.
The `generic` secrets engine can be used for [`kv-v1`, AWS, Artifactory and other similar vault secret engines](#vault-secrets-engines).

## Configure Vault server roles

When a CI job attempts to authenticate, it specifies a role. You can use roles to group
different policies together. If authentication is successful, these policies are
attached to the resulting Vault token.

[Bound claims](https://developer.hashicorp.com/vault/docs/auth/jwt#bound-claims) are predefined
values that are matched to the JWT claims. With bounded claims, you can restrict access
to specific GitLab users, specific projects, or even jobs running for specific Git
references. You can have as many bounded claims you need, but they must *all* match
for authentication to be successful.

Combining bounded claims with GitLab features like [user roles](../../user/permissions.md)
and [protected branches](../../user/project/repository/branches/protected.md), you can tailor
these rules to fit your specific use case. In this example, authentication is allowed
only for jobs running for protected tags with names matching the pattern used for
production releases:

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
    "project_id": "42",
    "ref_protected": "true",
    "ref_type": "tag",
    "ref": "auto-deploy-*"
  }
}
EOF
```

WARNING:
Always restrict your roles to a project or namespace by using one of the provided
claims like `project_id` or `namespace_id`. Without these restrictions, any JWT
generated by this GitLab instance may be allowed to authenticate using this role.

For a full list of ID token JWT claims, read the
[How It Works](hashicorp_vault.md) section of the
[Authenticating and Reading Secrets With HashiCorp Vault](hashicorp_vault.md) tutorial.

You can also specify some attributes for the resulting Vault tokens, such as time-to-live,
IP address range, and number of uses. The full list of options is available in
[Vault's documentation on creating roles](https://developer.hashicorp.com/vault/api-docs/auth/jwt#create-role)
for the JSON web token method.

## Using a self-signed Vault server

When the Vault server is using a self-signed certificate, you see the following error in the job logs:

```plaintext
ERROR: Job failed (system failure): resolving secrets: initializing Vault service: preparing authenticated client: checking Vault server health: Get https://vault.example.com:8000/v1/sys/health?drsecondarycode=299&performancestandbycode=299&sealedcode=299&standbycode=299&uninitcode=299: x509: certificate signed by unknown authority
```

You have two options to solve this error:

- Add the self-signed certificate to the GitLab Runner server's CA store.
  If you deployed GitLab Runner using the [Helm chart](https://docs.gitlab.com/runner/install/kubernetes.html), you have to create your own GitLab Runner image.
- Use the `VAULT_CACERT` environment variable to configure GitLab Runner to trust the certificate:
  - If you are using systemd to manage GitLab Runner, see [how to add an environment variable for GitLab Runner](https://docs.gitlab.com/runner/configuration/init.html#setting-custom-environment-variables).
  - If you deployed GitLab Runner using the [Helm chart](https://docs.gitlab.com/runner/install/kubernetes.html):
    1. [Provide a custom certificate for accessing GitLab](https://docs.gitlab.com/runner/install/kubernetes_helm_chart_configuration.html#access-gitlab-with-a-custom-certificate), and make sure to add the certificate for the Vault server instead of the certificate for GitLab. If your GitLab instance is also using a self-signed certificate, you should be able to add both in the same `Secret`.
    1. Add the following lines in your `values.yaml` file:

       ```yaml
       ## Replace both the <SECRET_NAME> and the <VAULT_CERTIFICATE>
       ## with the actual values you used to create the secret

       certsSecretName: <SECRET_NAME>

       envVars:
         - name: VAULT_CACERT
           value: "/home/gitlab-runner/.gitlab-runner/certs/<VAULT_CERTIFICATE>"
       ```

## Troubleshooting

### `resolving secrets: secret not found: MY_SECRET` error

When GitLab is unable to find the secret in the vault, you might receive this error:

```plaintext
ERROR: Job failed (system failure): resolving secrets: secret not found: MY_SECRET
```

Check that the `vault` value is [correctly configured in the CI/CD job](#use-vault-secrets-in-a-ci-job).

You can use the [`kv` command with the Vault CLI](https://developer.hashicorp.com/vault/docs/commands/kv)
to check if the secret is retrievable to help determine the syntax for the `vault`
value in your CI/CD configuration. For example, to retrieve the secret:

```shell
$ vault kv get -field=password -namespace=admin -mount=ops "production/db"
this-is-a-password
```

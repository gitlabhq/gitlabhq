---
stage: Security Platform
group: Secrets Manager Application
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Access secrets from non-CI/CD workloads
---

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Status: Beta

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/594090) in GitLab 19.2 [with a flag](../../../administration/feature_flags/_index.md) named `secrets_manager_api_access`. Disabled by default.

{{< /history >}}

CI/CD jobs read [GitLab Secrets Manager](_index.md) secrets through the GitLab Runner.
Other workloads read secrets through the [Secrets Manager API](../../../api/secrets_manager.md).
Examples include Kubernetes applications and infrastructure as code tools.

Reads go directly to the OpenBao backend, so secret availability does not depend on the GitLab application.

## Access token flow

1. A client authenticates to GitLab with a personal access token, a service account token,
   or a project or group access token that has the `api` scope.
1. The client calls the Secrets Manager API to mint a short-lived access token.
   The response includes the token and the OpenBao connection details.
1. The client presents the token to the OpenBao backend to read the secret value.

The access token expires after five minutes.
Because OpenBao implements the Vault API, you can present the token with any
[HashiCorp Vault](https://developer.hashicorp.com/vault) compatible client.

Every OpenBao connection detail comes from the mint response, so you do not
construct namespace, mount, or authentication paths yourself.

## Prerequisites

- Secrets Manager is enabled for the project or group.
- You authenticate with a personal access token, project or group access token, or service account
  token that has the `api` scope.
- Your role is at least Reporter.
- To read a secret value, you are granted the read value permission for that secret.
  The Reporter role alone does not expose secret values.

## Read a secret

This example mints an access token for a project, authenticates to OpenBao, then reads a secret value.

1. Mint an access token. The token you authenticate with must have the `api` scope:

   ```shell
   RESPONSE=$(curl --silent --request POST \
     --header "PRIVATE-TOKEN: <your_access_token>" \
     --url "https://gitlab.example.com/api/v4/projects/<project_id>/secrets_manager/access_token")
   ```

   The response contains a `provider.vault` object with `server`, `namespace`, `path`,
   `secrets_path`, and `auth.jwt` details, plus a short-lived `token`.

1. Authenticate to OpenBao with the returned token, then read the value:

   ```shell
   SERVER=$(echo "$RESPONSE" | jq --raw-output .provider.vault.server)
   NAMESPACE=$(echo "$RESPONSE" | jq --raw-output .provider.vault.namespace)
   MOUNT=$(echo "$RESPONSE" | jq --raw-output .provider.vault.path)
   SECRETS_PATH=$(echo "$RESPONSE" | jq --raw-output .provider.vault.secrets_path)
   AUTH_PATH=$(echo "$RESPONSE" | jq --raw-output .provider.vault.auth.jwt.path)
   ROLE=$(echo "$RESPONSE" | jq --raw-output .provider.vault.auth.jwt.role)
   JWT=$(echo "$RESPONSE" | jq --raw-output .provider.vault.auth.jwt.token)

   # Exchange the JWT for a short-lived OpenBao token.
   VAULT_TOKEN=$(curl --silent --request POST \
     --header "X-Vault-Namespace: $NAMESPACE" \
     --data "{\"role\":\"$ROLE\",\"jwt\":\"$JWT\"}" \
     "$SERVER/v1/auth/$AUTH_PATH/login" | jq --raw-output .auth.client_token)

   # Read the secret value.
   curl --silent \
     --header "X-Vault-Token: $VAULT_TOKEN" \
     --header "X-Vault-Namespace: $NAMESPACE" \
     "$SERVER/v1/$MOUNT/data/$SECRETS_PATH/<secret_name>"
   ```

On GitLab.com, `server` is `https://secrets.gitlab.com`.
On GitLab Self-Managed, `server` is the OpenBao URL configured for the instance.

For the full request and response format, see [the Secrets Manager API](../../../api/secrets_manager.md).

## Use with the Vault CLI

Because OpenBao implements the Vault API, you can use the
[Vault CLI](https://developer.hashicorp.com/vault/docs/commands) with the values from the response:

```shell
export VAULT_ADDR="<server>"
export VAULT_NAMESPACE="<namespace>"

# Exchange the minted JWT for an OpenBao token, then export it.
vault write "auth/<auth_jwt_path>/login" role=<role> jwt=<token>
export VAULT_TOKEN="<client_token>"

# Read the secret value.
vault kv get -mount=<path> "<secrets_path>/<secret_name>"
```

## Use with the External Secrets Operator

The [External Secrets Operator](https://external-secrets.io) syncs GitLab secrets into Kubernetes
secrets through its HashiCorp Vault provider.
A workload in the cluster keeps a fresh access token in a Kubernetes secret, and the operator reads
that token to authenticate to OpenBao.

Map the mint response onto a `SecretStore`, and reference each secret by `<secrets_path>/<secret_name>`:

```yaml
apiVersion: external-secrets.io/v1
kind: SecretStore
metadata:
  name: gitlab-secrets-manager
  namespace: my-app
spec:
  provider:
    vault:
      server: https://secrets.gitlab.com     # provider.vault.server
      path: secrets/kv                        # provider.vault.path
      version: v2
      namespace: org_5/group_42/project_99    # provider.vault.namespace
      auth:
        jwt:
          path: api_jwt/cel                   # provider.vault.auth.jwt.path
          role: all_api                       # provider.vault.auth.jwt.role
          secretRef:
            name: gitlab-access-token         # Kubernetes secret holding the minted token
            key: token
---
apiVersion: external-secrets.io/v1
kind: ExternalSecret
metadata:
  name: my-secret
  namespace: my-app
spec:
  refreshInterval: 1m
  secretStoreRef:
    name: gitlab-secrets-manager
    kind: SecretStore
  target:
    name: synced-secret
  data:
    - secretKey: value
      remoteRef:
        key: explicit/<secret_name>           # <secrets_path>/<secret_name>
        property: value
```

The access token expires after five minutes, so a workload must refresh the `gitlab-access-token`
Kubernetes secret before it expires.

A native Kubernetes integration is proposed in [epic 20382](https://gitlab.com/groups/gitlab-org/-/epics/20382).

## Use with Terraform

A Terraform or OpenTofu configuration can read GitLab secrets as a data source.
Terraform cannot mint the access token itself, so an
[`external` data source](https://registry.terraform.io/providers/hashicorp/external/latest/docs/data-sources/external)
runs a script that calls the Secrets Manager API and returns the `provider.vault` connection details.
The [Vault provider](https://registry.terraform.io/providers/hashicorp/vault/latest/docs) then
authenticates with the minted JWT and reads the secret.

The script mints the token and prints the connection details as JSON. It reads the GitLab
token from the `GITLAB_TOKEN` environment variable:

```shell
#!/usr/bin/env bash
# scripts/mint_token.sh
set -euo pipefail
eval "$(jq --raw-output '@sh "PROJECT_ID=\(.project_id)"')"

curl --silent --request POST \
  --header "PRIVATE-TOKEN: ${GITLAB_TOKEN}" \
  --url "https://gitlab.example.com/api/v4/projects/${PROJECT_ID}/secrets_manager/access_token" \
  | jq '{
      server:       .provider.vault.server,
      namespace:    .provider.vault.namespace,
      mount:        .provider.vault.path,
      secrets_path: .provider.vault.secrets_path,
      auth_path:    .provider.vault.auth.jwt.path,
      role:         .provider.vault.auth.jwt.role,
      jwt:          .provider.vault.auth.jwt.token
    }'
```

Reference the script from an `external` data source, configure the Vault provider, then read the secret:

```hcl
data "external" "gitlab_secrets_token" {
  program = ["bash", "${path.module}/scripts/mint_token.sh"]

  query = {
    project_id = var.gitlab_project_id
  }
}

provider "vault" {
  address   = data.external.gitlab_secrets_token.result.server
  namespace = data.external.gitlab_secrets_token.result.namespace

  auth_login_jwt {
    mount = data.external.gitlab_secrets_token.result.auth_path
    role  = data.external.gitlab_secrets_token.result.role
    jwt   = data.external.gitlab_secrets_token.result.jwt
  }
}

data "vault_kv_secret_v2" "my_secret" {
  mount = data.external.gitlab_secrets_token.result.mount
  name  = "${data.external.gitlab_secrets_token.result.secrets_path}/<secret_name>"
}

output "secret_value" {
  value     = data.vault_kv_secret_v2.my_secret.data["value"]
  sensitive = true
}
```

The minted token is valid for five minutes, so `terraform apply` must run within that window.

A native GitLab Terraform provider integration is proposed in [epic 21177](https://gitlab.com/groups/gitlab-org/-/epics/21177).

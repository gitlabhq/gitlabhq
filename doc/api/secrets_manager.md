---
stage: Software Supply Chain Security
group: Pipeline Security
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Secrets Manager API
description: REST API to mint short-lived access tokens for GitLab Secrets Manager.
---

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Status: Beta

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/594090) in GitLab 19.2 [with a flag](../administration/feature_flags/_index.md) named `secrets_manager_api_access`. Disabled by default.

{{< /history >}}

Use this API to access [GitLab Secrets Manager](../ci/secrets/secrets_manager/_index.md) secrets from non-CI/CD workloads.

The API mints a short-lived JSON web token (JWT) for a project or group.
A client presents this token to the OpenBao backend to read secrets directly,
the same way GitLab Runner reads secrets during a CI/CD job.
The response includes the OpenBao connection details the client needs.

You call this API with a personal access token, project or group access token, or service account
token that has the `api` scope.
The token the API returns is a separate, short-lived OpenBao JWT, not a GitLab access token.
It expires after five minutes.
Reading a secret value also requires the principal to have the read value permission for that secret.

To use the returned connection details to read a secret, see
[Access secrets from non-CI/CD workloads](../ci/secrets/secrets_manager/non_cicd_access.md).

## Create a Secrets Manager access token for a project

Mints an access token for reading a project's secrets.

```plaintext
POST /projects/:id/secrets_manager/access_token
```

Supported attributes:

| Attribute | Type              | Required | Description |
|-----------|-------------------|----------|-------------|
| `id`      | integer or string | Yes      | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths). |

Example request:

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/secrets_manager/access_token"
```

Example response:

```json
{
  "expires_at": "2026-05-27T10:35:00Z",
  "provider": {
    "vault": {
      "server": "https://secrets.gitlab.com",
      "namespace": "org_5/group_42/project_99",
      "path": "secrets/kv",
      "version": "v2",
      "secrets_path": "explicit",
      "auth": {
        "jwt": {
          "path": "api_jwt/cel",
          "role": "all_api",
          "token": "<JWT>"
        }
      }
    }
  }
}
```

Response attributes:

| Attribute | Type | Description |
|-----------|------|-------------|
| `expires_at` | string | ISO 8601 timestamp when the token expires. Tokens are valid for five minutes. |
| `provider.vault.server` | string | URL of the OpenBao server to connect to. On GitLab.com this is `https://secrets.gitlab.com`. On GitLab Self-Managed it is the OpenBao URL configured for the instance. |
| `provider.vault.namespace` | string | OpenBao namespace that holds the project's secrets. Pass it as the `X-Vault-Namespace` header. |
| `provider.vault.path` | string | Mount path of the KV secrets engine. |
| `provider.vault.version` | string | Version of the KV secrets engine. |
| `provider.vault.secrets_path` | string | Base path under the KV engine where secrets are stored. Prepend it to a secret name to build the read path (`<path>/data/<secrets_path>/<secret_name>`). |
| `provider.vault.auth.jwt.path` | string | Mount path for the JWT authentication method. Authenticate at `auth/<path>/login`. |
| `provider.vault.auth.jwt.role` | string | JWT authentication role to log in with. |
| `provider.vault.auth.jwt.token` | string | Short-lived JWT the client presents to OpenBao. |

## Create a Secrets Manager access token for a group

Mints an access token for reading a group's secrets.

```plaintext
POST /groups/:id/secrets_manager/access_token
```

Supported attributes:

| Attribute | Type              | Required | Description |
|-----------|-------------------|----------|-------------|
| `id`      | integer or string | Yes      | The ID or [URL-encoded path of the group](rest/_index.md#namespaced-paths). |

Example request:

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/1/secrets_manager/access_token"
```

Example response:

```json
{
  "expires_at": "2026-05-27T10:35:00Z",
  "provider": {
    "vault": {
      "server": "https://secrets.gitlab.com",
      "namespace": "org_5/group_42/group_99",
      "path": "secrets/kv",
      "version": "v2",
      "secrets_path": "explicit",
      "auth": {
        "jwt": {
          "path": "api_jwt/cel",
          "role": "all_api",
          "token": "<JWT>"
        }
      }
    }
  }
}
```

The response attributes are the same as for
[Create a Secrets Manager access token for a project](#create-a-secrets-manager-access-token-for-a-project),
with `provider.vault.namespace` scoped to the group.

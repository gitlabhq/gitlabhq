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

The token expires after 5 minutes.
Reading a secret value also requires the principal to have the read value permission for that secret.

## Create a project access token

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
      "server": "https://openbao.example.com",
      "namespace": "org_5/ns_42/project_99",
      "path": "secrets/kv",
      "version": "v2",
      "auth": {
        "jwt": {
          "path": "api_jwt",
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
| `expires_at` | string | ISO 8601 timestamp when the token expires. Tokens are valid for 5 minutes. |
| `provider.vault.server` | string | URL of the OpenBao server to connect to. |
| `provider.vault.namespace` | string | OpenBao namespace that holds the project's secrets. |
| `provider.vault.path` | string | Mount path of the KV secrets engine. |
| `provider.vault.version` | string | Version of the KV secrets engine. |
| `provider.vault.auth.jwt.path` | string | Mount path of the JWT authentication method. |
| `provider.vault.auth.jwt.role` | string | JWT authentication role to log in with. |
| `provider.vault.auth.jwt.token` | string | Short-lived JWT the client presents to OpenBao. |

## Create a group access token

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
      "server": "https://openbao.example.com",
      "namespace": "org_5/group_42",
      "path": "secrets/kv",
      "version": "v2",
      "auth": {
        "jwt": {
          "path": "api_jwt",
          "role": "all_api",
          "token": "<JWT>"
        }
      }
    }
  }
}
```

The response attributes are the same as for [Create a project access token](#create-a-project-access-token), with `provider.vault.namespace` scoped to the group.

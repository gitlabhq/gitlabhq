---
stage: Configure
group: Configure
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Agent Tokens API **(FREE)**

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/347046) in GitLab 15.0.

Use the Agent Tokens API to manage tokens for the GitLab agent for Kubernetes.

## List tokens for an agent

Returns a list of tokens for an agent.

You must have at least the Developer role to use this endpoint.

```plaintext
GET /projects/:id/cluster_agents/:agent_id/tokens
```

Supported attributes:

| Attribute  | Type              | Required  | Description                                                                                                      |
|------------|-------------------|-----------|------------------------------------------------------------------------------------------------------------------|
| `id`       | integer or string | yes       | ID or [URL-encoded path of the project](index.md#namespaced-path-encoding) maintained by the authenticated user. |
| `agent_id` | integer or string | yes       | ID of the agent.                                                                                                 |

Response:

The response is a list of tokens with the following fields:

| Attribute            | Type           | Description                                                       |
|----------------------|----------------|-------------------------------------------------------------------|
| `id`                 | integer        | ID of the token.                                                  |
| `name`               | string         | Name of the token.                                                |
| `description`        | string or null | Description of the token.                                         |
| `agent_id`           | integer        | ID of the agent the token belongs to.                             |
| `status`             | string         | The status of the token. Valid values are `active` and `revoked`. |
| `created_at`         | string         | ISO8601 datetime when the token was created.                      |
| `created_by_user_id` | string         | User ID of the user who created the token.                        |

Example request:

```shell
curl --header "Private-Token: <your_access_token>" "https://gitlab.example.com/api/v4/projects/20/cluster_agents/5/tokens"
```

Example response:

```json
[
  {
    "id": 1,
    "name": "abcd",
    "description": "Some token",
    "agent_id": 5,
    "status": "active",
    "created_at": "2022-03-25T14:12:11.497Z",
    "created_by_user_id": 1
  },
  {
    "id": 2,
    "name": "foobar",
    "description": null,
    "agent_id": 5,
    "status": "active",
    "created_at": "2022-03-25T14:12:11.497Z",
    "created_by_user_id": 1
  }
]
```

NOTE:
The `last_used_at` field for a token is only returned when getting a single agent token.

## Get a single agent token

Gets a single agent token.

You must have at least the Developer role to use this endpoint.

```shell
GET /projects/:id/cluster_agents/:agent_id/tokens/:token_id
```

Supported attributes:

| Attribute  | Type              | Required | Description                                                                                                       |
|------------|-------------------|----------|-------------------------------------------------------------------------------------------------------------------|
| `id`       | integer or string | yes      | ID or [URL-encoded path of the project](index.md#namespaced-path-encoding) maintained by the authenticated user.  |
| `agent_id` | integer           | yes      | ID of the agent.                                                                                                  |
| `token_id` | integer           | yes      | ID of the token.                                                                                                  |

Response:

The response is a single token with the following fields:

| Attribute            | Type           | Description                                                       |
|----------------------|----------------|-------------------------------------------------------------------|
| `id`                 | integer        | ID of the token.                                                  |
| `name`               | string         | Name of the token.                                                |
| `description`        | string or null | Description of the token.                                         |
| `agent_id`           | integer        | ID of the agent the token belongs to.                             |
| `status`             | string         | The status of the token. Valid values are `active` and `revoked`. |
| `created_at`         | string         | ISO8601 datetime when the token was created.                      |
| `created_by_user_id` | string         | User ID of the user who created the token.                        |
| `last_used_at`       | string or null | ISO8601 datetime when the token was last used.                    |

Example request:

```shell
curl --header "Private-Token: <your_access_token>" "https://gitlab.example.com/api/v4/projects/20/cluster_agents/5/token/1"
```

Example response:

```json
{
  "id": 1,
  "name": "abcd",
  "description": "Some token",
  "agent_id": 5,
  "status": "active",
  "created_at": "2022-03-25T14:12:11.497Z",
  "created_by_user_id": 1,
  "last_used_at": null
}
```

## Create an agent token

Creates a new token for an agent.

You must have at least the Maintainer role to use this endpoint.

```shell
POST /projects/:id/cluster_agents/:agent_id/tokens
```

Supported attributes:

| Attribute     | Type              | Required | Description                                                                                                      |
|---------------|-------------------|----------|------------------------------------------------------------------------------------------------------------------|
| `id`          | integer or string | yes      | ID or [URL-encoded path of the project](index.md#namespaced-path-encoding) maintained by the authenticated user. |
| `agent_id`    | integer           | yes      | ID of the agent.                                                                                                 |
| `name`        | string            | yes      | Name for the token.                                                                                              |
| `description` | string            | no       | Description for the token.                                                                                       |       

Response:

The response is the new token with the following fields:

| Attribute            | Type           | Description                                                       |
|----------------------|----------------|-------------------------------------------------------------------|
| `id`                 | integer        | ID of the token.                                                  |
| `name`               | string         | Name of the token.                                                |
| `description`        | string or null | Description of the token.                                         |
| `agent_id`           | integer        | ID of the agent the token belongs to.                             |
| `status`             | string         | The status of the token. Valid values are `active` and `revoked`. |
| `created_at`         | string         | ISO8601 datetime when the token was created.                      |
| `created_by_user_id` | string         | User ID of the user who created the token.                        |
| `last_used_at`       | string or null | ISO8601 datetime when the token was last used.                    |
| `token`              | string         | The secret token value.                                           |

NOTE:
The `token` is only returned in the response of the `POST` endpoint and cannot be retrieved afterwards.

Example request:

```shell
curl --header "Private-Token: <your_access_token>" "https://gitlab.example.com/api/v4/projects/20/cluster_agents/5/tokens" \
    -H "Content-Type:application/json" \
    -X POST --data '{"name":"some-token"}'
```

Example response:

```json
{
  "id": 1,
  "name": "abcd",
  "description": "Some token",
  "agent_id": 5,
  "status": "active",
  "created_at": "2022-03-25T14:12:11.497Z",
  "created_by_user_id": 1,
  "last_used_at": null,
  "token": "qeY8UVRisx9y3Loxo1scLxFuRxYcgeX3sxsdrpP_fR3Loq4xyg"
}
```

## Revoke an agent token

Revokes an agent token.

You must have at least the Maintainer role to use this endpoint.

```plaintext
DELETE /projects/:id/cluster_agents/:agent_id/tokens/:token_id
```

Supported attributes:

| Attribute  | Type              | Required | Description                                                                                                      |
|------------|-------------------|----------|---------------------------------------------------------------------------------------------------------------- -|
| `id`       | integer or string | yes      | ID or [URL-encoded path of the project](index.md#namespaced-path-encoding) maintained by the authenticated user. |
| `agent_id` | integer           | yes      | ID of the agent.                                                                                                 |
| `token_id` | integer           | yes      | ID of the token.                                                                                                 |

Example request:

```shell
curl --request DELETE --header "Private-Token: <your_access_token>" "https://gitlab.example.com/api/v4/projects/20/cluster_agents/5/tokens/1
```

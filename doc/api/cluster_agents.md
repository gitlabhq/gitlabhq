---
stage: Deploy
group: Environments
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Agents API **(FREE)**

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/83270) in GitLab 14.10.
> - Agent Tokens API [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/347046) in GitLab 15.0.

Use the Agents API to work with the GitLab agent for Kubernetes.

## List the agents for a project

Returns the list of agents registered for the project.

You must have at least the Developer role to use this endpoint.

```plaintext
GET /projects/:id/cluster_agents
```

Parameters:

| Attribute | Type              | Required  | Description                                                                                                     |
|-----------|-------------------|-----------|-----------------------------------------------------------------------------------------------------------------|
| `id`      | integer or string | yes       | ID or [URL-encoded path of the project](rest/index.md#namespaced-path-encoding) maintained by the authenticated user |

Response:

The response is a list of agents with the following fields:

| Attribute                            | Type     | Description                                          |
|--------------------------------------|----------|------------------------------------------------------|
| `id`                                 | integer  | ID of the agent                                      |
| `name`                               | string   | Name of the agent                                    |
| `config_project`                     | object   | Object representing the project the agent belongs to |
| `config_project.id`                  | integer  | ID of the project                                    |
| `config_project.description`         | string   | Description of the project                           |
| `config_project.name`                | string   | Name of the project                                  |
| `config_project.name_with_namespace` | string   | Full name with namespace of the project              |
| `config_project.path`                | string   | Path to the project                                  |
| `config_project.path_with_namespace` | string   | Full path with namespace to the project              |
| `config_project.created_at`          | string   | ISO8601 datetime when the project was created        |
| `created_at`                         | string   | ISO8601 datetime when the agent was created          |
| `created_by_user_id`                 | integer  | ID of the user who created the agent                 |

Example request:

```shell
curl --header "Private-Token: <your_access_token>" "https://gitlab.example.com/api/v4/projects/20/cluster_agents"
```

Example response:

```json
[
  {
    "id": 1,
    "name": "agent-1",
    "config_project": {
      "id": 20,
      "description": "",
      "name": "test",
      "name_with_namespace": "Administrator / test",
      "path": "test",
      "path_with_namespace": "root/test",
      "created_at": "2022-03-20T20:42:40.221Z"
    },
    "created_at": "2022-04-20T20:42:40.221Z",
    "created_by_user_id": 42
  },
  {
    "id": 2,
    "name": "agent-2",
    "config_project": {
      "id": 20,
      "description": "",
      "name": "test",
      "name_with_namespace": "Administrator / test",
      "path": "test",
      "path_with_namespace": "root/test",
      "created_at": "2022-03-20T20:42:40.221Z"
    },
    "created_at": "2022-04-20T20:42:40.221Z",
    "created_by_user_id": 42
  }
]
```

## Get details about an agent

Gets a single agent details.

You must have at least the Developer role to use this endpoint.

```plaintext
GET /projects/:id/cluster_agents/:agent_id
```

Parameters:

| Attribute  | Type              | Required | Description                                                                                                     |
|------------|-------------------|----------|-----------------------------------------------------------------------------------------------------------------|
| `id`       | integer or string | yes      | ID or [URL-encoded path of the project](rest/index.md#namespaced-path-encoding) maintained by the authenticated user |
| `agent_id` | integer           | yes      | ID of the agent                                                                                                 |

Response:

The response is a single agent with the following fields:

| Attribute                            | Type    | Description                                          |
|--------------------------------------|---------|------------------------------------------------------|
| `id`                                 | integer | ID of the agent                                      |
| `name`                               | string  | Name of the agent                                    |
| `config_project`                     | object  | Object representing the project the agent belongs to |
| `config_project.id`                  | integer | ID of the project                                    |
| `config_project.description`         | string  | Description of the project                           |
| `config_project.name`                | string  | Name of the project                                  |
| `config_project.name_with_namespace` | string  | Full name with namespace of the project              |
| `config_project.path`                | string  | Path to the project                                  |
| `config_project.path_with_namespace` | string  | Full path with namespace to the project              |
| `config_project.created_at`          | string  | ISO8601 datetime when the project was created        |
| `created_at`                         | string  | ISO8601 datetime when the agent was created          |
| `created_by_user_id`                 | integer | ID of the user who created the agent                 |

Example request:

```shell
curl --header "Private-Token: <your_access_token>" "https://gitlab.example.com/api/v4/projects/20/cluster_agents/1"
```

Example response:

```json
{
  "id": 1,
  "name": "agent-1",
  "config_project": {
    "id": 20,
    "description": "",
    "name": "test",
    "name_with_namespace": "Administrator / test",
    "path": "test",
    "path_with_namespace": "root/test",
    "created_at": "2022-03-20T20:42:40.221Z"
  },
  "created_at": "2022-04-20T20:42:40.221Z",
  "created_by_user_id": 42
}
```

## Register an agent with a project

Registers an agent to the project.

You must have at least the Maintainer role to use this endpoint.

```plaintext
POST /projects/:id/cluster_agents
```

Parameters:

| Attribute | Type              | Required | Description                                                                                                     |
|-----------|-------------------|----------|-----------------------------------------------------------------------------------------------------------------|
| `id`      | integer or string | yes      | ID or [URL-encoded path of the project](rest/index.md#namespaced-path-encoding) maintained by the authenticated user |
| `name`    | string            | yes      | Name for the agent                                                                                              |

Response:

The response is the new agent with the following fields:

| Attribute                            | Type    | Description                                          |
|--------------------------------------|---------|------------------------------------------------------|
| `id`                                 | integer | ID of the agent                                      |
| `name`                               | string  | Name of the agent                                    |
| `config_project`                     | object  | Object representing the project the agent belongs to |
| `config_project.id`                  | integer | ID of the project                                    |
| `config_project.description`         | string  | Description of the project                           |
| `config_project.name`                | string  | Name of the project                                  |
| `config_project.name_with_namespace` | string  | Full name with namespace of the project              |
| `config_project.path`                | string  | Path to the project                                  |
| `config_project.path_with_namespace` | string  | Full path with namespace to the project              |
| `config_project.created_at`          | string  | ISO8601 datetime when the project was created        |
| `created_at`                         | string  | ISO8601 datetime when the agent was created          |
| `created_by_user_id`                 | integer | ID of the user who created the agent                 |

Example request:

```shell
curl --header "Private-Token: <your_access_token>" "https://gitlab.example.com/api/v4/projects/20/cluster_agents" \
    -H "Content-Type:application/json" \
    -X POST --data '{"name":"some-agent"}'
```

Example response:

```json
{
  "id": 1,
  "name": "agent-1",
  "config_project": {
    "id": 20,
    "description": "",
    "name": "test",
    "name_with_namespace": "Administrator / test",
    "path": "test",
    "path_with_namespace": "root/test",
    "created_at": "2022-03-20T20:42:40.221Z"
  },
  "created_at": "2022-04-20T20:42:40.221Z",
  "created_by_user_id": 42
}
```

## Delete a registered agent

Deletes an existing agent registration.

You must have at least the Maintainer role to use this endpoint.

```plaintext
DELETE /projects/:id/cluster_agents/:agent_id
```

Parameters:

| Attribute  | Type              | Required | Description                                                                                                     |
|------------|-------------------|----------|-----------------------------------------------------------------------------------------------------------------|
| `id`       | integer or string | yes      | ID or [URL-encoded path of the project](rest/index.md#namespaced-path-encoding) maintained by the authenticated user |
| `agent_id` | integer           | yes      | ID of the agent                                                                                                 |

Example request:

```shell
curl --request DELETE --header "Private-Token: <your_access_token>" "https://gitlab.example.com/api/v4/projects/20/cluster_agents/1
```

## List tokens for an agent

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/347046) in GitLab 15.0.

Returns a list of active tokens for an agent.

You must have at least the Developer role to use this endpoint.

```plaintext
GET /projects/:id/cluster_agents/:agent_id/tokens
```

Supported attributes:

| Attribute  | Type              | Required  | Description                                                                                                      |
|------------|-------------------|-----------|------------------------------------------------------------------------------------------------------------------|
| `id`       | integer or string | yes       | ID or [URL-encoded path of the project](rest/index.md#namespaced-path-encoding) maintained by the authenticated user. |
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

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/347046) in GitLab 15.0.

Gets a single agent token.

You must have at least the Developer role to use this endpoint.

Returns a `404` if the agent token has been revoked.

```plaintext
GET /projects/:id/cluster_agents/:agent_id/tokens/:token_id
```

Supported attributes:

| Attribute  | Type              | Required | Description                                                                                                       |
|------------|-------------------|----------|-------------------------------------------------------------------------------------------------------------------|
| `id`       | integer or string | yes      | ID or [URL-encoded path of the project](rest/index.md#namespaced-path-encoding) maintained by the authenticated user.  |
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

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/347046) in GitLab 15.0.

Creates a new token for an agent.

You must have at least the Maintainer role to use this endpoint.

```plaintext
POST /projects/:id/cluster_agents/:agent_id/tokens
```

Supported attributes:

| Attribute     | Type              | Required | Description                                                                                                      |
|---------------|-------------------|----------|------------------------------------------------------------------------------------------------------------------|
| `id`          | integer or string | yes      | ID or [URL-encoded path of the project](rest/index.md#namespaced-path-encoding) maintained by the authenticated user. |
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

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/347046) in GitLab 15.0.

Revokes an agent token.

You must have at least the Maintainer role to use this endpoint.

```plaintext
DELETE /projects/:id/cluster_agents/:agent_id/tokens/:token_id
```

Supported attributes:

| Attribute  | Type              | Required | Description                                                                                                      |
|------------|-------------------|----------|---------------------------------------------------------------------------------------------------------------- -|
| `id`       | integer or string | yes      | ID or [URL-encoded path of the project](rest/index.md#namespaced-path-encoding) maintained by the authenticated user. |
| `agent_id` | integer           | yes      | ID of the agent.                                                                                                 |
| `token_id` | integer           | yes      | ID of the token.                                                                                                 |

Example request:

```shell
curl --request DELETE --header "Private-Token: <your_access_token>" "https://gitlab.example.com/api/v4/projects/20/cluster_agents/5/tokens/1
```

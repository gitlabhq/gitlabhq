---
stage: Configure
group: Configure
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Agents API **(FREE)**

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/83270) in GitLab 14.10.

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
| `id`      | integer or string | yes       | ID or [URL-encoded path of the project](index.md#namespaced-path-encoding) maintained by the authenticated user |

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

```shell
GET /projects/:id/cluster_agents/:agent_id
```

Parameters:

| Attribute  | Type              | Required | Description                                                                                                     |
|------------|-------------------|----------|-----------------------------------------------------------------------------------------------------------------|
| `id`       | integer or string | yes      | ID or [URL-encoded path of the project](index.md#namespaced-path-encoding) maintained by the authenticated user |
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

```shell
POST /projects/:id/cluster_agents
```

Parameters:

| Attribute | Type              | Required | Description                                                                                                     |
|-----------|-------------------|----------|-----------------------------------------------------------------------------------------------------------------|
| `id`      | integer or string | yes      | ID or [URL-encoded path of the project](index.md#namespaced-path-encoding) maintained by the authenticated user |
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
| `id`       | integer or string | yes      | ID or [URL-encoded path of the project](index.md#namespaced-path-encoding) maintained by the authenticated user |
| `agent_id` | integer           | yes      | ID of the agent                                                                                                 |

Example request:

```shell
curl --request DELETE --header "Private-Token: <your_access_token>" "https://gitlab.example.com/api/v4/projects/20/cluster_agents/1
```

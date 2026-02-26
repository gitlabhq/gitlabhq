---
stage: AI-powered
group: Agent Foundations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: REST API to create, start, and manage GitLab Duo Agent Platform flows.
title: Duo Agent Platform flows API
---

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Use this API to create and manage [flows](../user/duo_agent_platform/flows/_index.md) in the
[GitLab Duo Agent Platform](../user/duo_agent_platform/_index.md).
Flows are combinations of AI agents that work together to complete developer tasks,
such as fixing bugs, writing code, or resolving vulnerabilities.

## Create a flow

{{< details >}}

- Status: Experiment

{{< /details >}}

Creates and starts a new flow.

```plaintext
POST /ai/duo_workflows/workflows
```

Supported attributes:

| Attribute | Type | Required | Description |
|-----------|------|----------|-------------|
| `additional_context` | array of objects | No | Additional context for the flow. Each element must be an object with at minimum a `Category` (string) and `Content` (string, serialized JSON) key. |
| `agent_privileges` | integer array | No | Privilege IDs the agent is allowed to use. Defaults to all privileges. See [List all agent privileges](#list-all-agent-privileges). |
| `ai_catalog_item_consumer_id` | integer | No | ID of the AI Catalog item consumer that configures which catalog item to execute. Requires `project_id`. Cannot be used with `workflow_definition`; if both are provided, `ai_catalog_item_consumer_id` takes precedence. See [Look up the consumer ID](#look-up-the-consumer-id). |
| `ai_catalog_item_version_id` | integer | No | ID of the AI Catalog item version that sourced the flow configuration. |
| `allow_agent_to_request_user` | boolean | No | When `true` (default), the agent may pause to ask the user questions before proceeding. When `false`, the agent runs to completion without user input. |
| `environment` | string | No | Execution environment. One of: `ide`, `web`, `chat_partial`, `chat`, `ambient`. |
| `goal` | string | No | Description of the task for the agent to complete. Example: `Fix the failing pipeline`. |
| `image` | string | No | Container image to use when running the flow in a CI pipeline. Must meet the [custom image requirements](../user/duo_agent_platform/flows/execution.md#custom-image-requirements). Example: `registry.gitlab.com/gitlab-org/duo-workflow/custom-image:latest`. |
| `issue_id` | integer | No | IID of the issue to associate the flow with. Requires `project_id`. |
| `merge_request_id` | integer | No | IID of the merge request to associate the flow with. Requires `project_id`. |
| `namespace_id` | string | No | ID or path of the namespace to associate the flow with. |
| `pre_approved_agent_privileges` | integer array | No | Privilege IDs the agent can use without asking for user approval. Must be a subset of `agent_privileges`. |
| `project_id` | string | No | ID or path of the project to associate the flow with. |
| `shallow_clone` | boolean | No | Whether to use a shallow clone of the repository during execution. Default: `true`. |
| `source_branch` | string | No | Source branch for the CI pipeline. Defaults to the project's default branch. |
| `start_workflow` | boolean | No | When `true`, starts the flow immediately after creation. |
| `workflow_definition` | string | No | Flow type identifier. Example: `developer/v1`. Cannot be used with `ai_catalog_item_consumer_id`; if both are provided, `ai_catalog_item_consumer_id` takes precedence. |

If successful, returns [`201 Created`](rest/troubleshooting.md#status-codes) and the following response
attributes:

| Attribute | Type | Description |
|-----------|------|-------------|
| `agent_privileges` | integer array | Privilege IDs assigned to the agent. |
| `agent_privileges_names` | string array | Names corresponding to `agent_privileges`. |
| `ai_catalog_item_version_id` | integer | ID of the AI Catalog item version. `null` if not set. |
| `allow_agent_to_request_user` | boolean | When `true`, the agent may pause for user input. |
| `environment` | string | Execution environment. `null` if not set. |
| `gitlab_url` | string | Base URL of the GitLab instance. |
| `id` | integer | ID of the flow. |
| `image` | string | Container image for CI pipeline execution. `null` if not set. |
| `mcp_enabled` | boolean | Whether `MCP` (Model Context Protocol) tools are enabled for this flow. |
| `namespace_id` | integer | ID of the associated namespace. `null` if not set. |
| `pre_approved_agent_privileges` | integer array | Privilege IDs the agent can use without asking for approval. |
| `pre_approved_agent_privileges_names` | string array | Names corresponding to `pre_approved_agent_privileges`. |
| `project_id` | integer | ID of the associated project. `null` if not set. |
| `status` | string | Current flow status. One of `created`, `running`, `paused`, `finished`, `failed`, `stopped`, `input_required`, `plan_approval_required`, or `tool_call_approval_required`. |
| `workflow_definition` | string | Flow type identifier. |
| `workload` | object | Information about the workload. |
| `workload.id` | string | ID of the workload. |
| `workload.message` | string | Status message for the workload. |

### Look up the consumer ID

Before you can use `ai_catalog_item_consumer_id`, you must use the GraphQL API to retrieve the ID from the [AI Catalog](../user/duo_agent_platform/ai_catalog.md). 
The item must already be enabled for the project.

```graphql
query {
  aiCatalogConfiguredItems(projectId: "gid://gitlab/Project/<project_id>") {
    nodes {
      id
      item { name }
    }
  }
}
```

The `id` field is a Global ID in the format `gid://gitlab/AiCatalogItemConsumer/<numeric_id>`.
Use the numeric suffix as the `ai_catalog_item_consumer_id` value.

Example request using a built-in flow type:

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --header "Content-Type: application/json" \
  --data '{
    "project_id": "5",
    "goal": "Fix the failing pipeline by correcting the syntax error in .gitlab-ci.yml",
    "workflow_definition": "developer/v1",
    "start_workflow": true
  }' \
  --url "https://gitlab.example.com/api/v4/ai/duo_workflows/workflows"
```

Example request using a catalog-configured flow:

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --header "Content-Type: application/json" \
  --data '{
    "project_id": "5",
    "goal": "Fix the failing pipeline by correcting the syntax error in .gitlab-ci.yml",
    "ai_catalog_item_consumer_id": 12,
    "start_workflow": true
  }' \
  --url "https://gitlab.example.com/api/v4/ai/duo_workflows/workflows"
```

Example response:

```json
{
  "id": 1,
  "project_id": 5,
  "namespace_id": null,
  "agent_privileges": [1, 2, 3, 4, 5, 6],
  "agent_privileges_names": [
    "read_write_files",
    "read_only_gitlab",
    "read_write_gitlab",
    "run_commands",
    "use_git",
    "run_mcp_tools"
  ],
  "pre_approved_agent_privileges": [],
  "pre_approved_agent_privileges_names": [],
  "workflow_definition": "developer/v1",
  "status": "running",
  "allow_agent_to_request_user": true,
  "image": null,
  "environment": null,
  "ai_catalog_item_version_id": null,
  "workload": {
    "id": "abc-123",
    "message": "Workflow started"
  },
  "mcp_enabled": false,
  "gitlab_url": "https://gitlab.example.com"
}
```

## List all agent privileges

Lists all available agent privileges with their IDs, names, descriptions, and whether each is enabled
by default.

```plaintext
GET /ai/duo_workflows/workflows/agent_privileges
```

This endpoint has no supported attributes.

If successful, returns [`200 OK`](rest/troubleshooting.md#status-codes) and the following response
attributes:

| Attribute | Type | Description |
|-----------|------|-------------|
| `all_privileges` | array of objects | All available agent privileges. |
| `all_privileges[].default_enabled` | boolean | Whether the privilege is enabled by default. |
| `all_privileges[].description` | string | Human-readable description of what the privilege permits. |
| `all_privileges[].id` | integer | Privilege ID. |
| `all_privileges[].name` | string | Machine-readable privilege name. |

Example request:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/ai/duo_workflows/workflows/agent_privileges"
```

Example response:

```json
{
  "all_privileges": [
    {
      "id": 1,
      "name": "read_write_files",
      "description": "Allow local filesystem read/write access",
      "default_enabled": true
    },
    {
      "id": 2,
      "name": "read_only_gitlab",
      "description": "Allow read only access to GitLab APIs",
      "default_enabled": true
    },
    {
      "id": 3,
      "name": "read_write_gitlab",
      "description": "Allow write access to GitLab APIs",
      "default_enabled": true
    },
    {
      "id": 4,
      "name": "run_commands",
      "description": "Allow running any commands",
      "default_enabled": true
    },
    {
      "id": 5,
      "name": "use_git",
      "description": "Allow git commits, push and other git commands",
      "default_enabled": true
    },
    {
      "id": 6,
      "name": "run_mcp_tools",
      "description": "Allow running MCP tools",
      "default_enabled": true
    }
  ]
}
```

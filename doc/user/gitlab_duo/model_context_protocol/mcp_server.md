---
stage: AI-powered
group: AI Framework
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: Connect AI tools to your GitLab instance with the official GitLab MCP server.
title: GitLab MCP server
---

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Status: Experiment

{{< /details >}}

{{< history >}}

- Introduced in GitLab 18.3 [with flags](../../../administration/feature_flags/_index.md) named `mcp_server` and `oauth_dynamic_client_registration`. Disabled by default.

{{< /history >}}

{{< alert type="flag" >}}

The availability of this feature is controlled by feature flags.
For more information, see the history.
This feature is available for testing, but not ready for production use.

{{< /alert >}}

{{< alert type="warning" >}}

To provide feedback on this feature, leave a comment on [issue 561564](https://gitlab.com/gitlab-org/gitlab/-/issues/561564).

{{< /alert >}}

With the GitLab [Model Context Protocol](https://modelcontextprotocol.io/) (MCP) server,
you can securely connect AI tools and applications to your GitLab instance.
AI assistants like Claude Desktop, Cursor, and other MCP-compatible tools
can then access your GitLab data and perform actions on your behalf.

The MCP server provides a standardized way for AI tools to:

- Access GitLab project information.
- Retrieve issue and merge request data.
- Interact with GitLab APIs securely.
- Perform GitLab-specific operations through AI assistants.

The GitLab MCP server supports [OAuth 2.0 Dynamic Client Registration](https://tools.ietf.org/html/rfc7591),
which enables AI tools to register themselves with your GitLab instance. When an AI tool connects to
your GitLab MCP server for the first time, it:

1. Registers itself as an OAuth application.
1. Requests authorization to access your GitLab data.
1. Receives an access token for secure API access.

For a click-through demo, see [Duo Agent Platform - MCP server](https://gitlab.navattic.com/gitlab-mcp-server).
<!-- Demo published on 2025-09-11 -->

## Connect Cursor to a GitLab MCP server

Prerequisites:

- You've installed [Node.js](https://nodejs.org/en/download) version 20 or later.

To configure the GitLab MCP server in Cursor:

1. Open Cursor.
1. In Cursor, go to **Settings** > **Cursor Settings** > **Tools & Integrations**.
1. Under **MCP Tools**, select `New MCP Server`.
1. Add this definition to the `mcpServers` key in the opened `mcp.json` file, editing as needed:
   - For the `"command":` parameter, if `npx` is installed locally instead of globally, provide the full path to `npx`.
   - Replace `<gitlab.example.com>` with:
     - On GitLab Self-Managed, your GitLab instance URL.
     - On GitLab.com, `GitLab.com`.
   - The `--static-oauth-client-metadata` parameter is mandatory for the `mcp-remote` module to set the OAuth scope to `mcp` as expected by the GitLab server.

   ```json
   {
     "mcpServers": {
       "GitLab": {
         "command": "npx",
         "args": [
           "mcp-remote",
           "https://<gitlab.example.com>/api/v4/mcp",
           "--static-oauth-client-metadata",
           "{\"scope\": \"mcp\"}"
         ]
       }
     }
   }
   ```

1. Save the file, and wait for your browser to open the OAuth authorization page.

   If this does not happen, close and restart Cursor.
1. In your browser, review and approve the authorization request.

The MCP server is now available in Cursor.

You can now start a new chat and ask a question about the MCP server version, a GitLab issue, or merge request depending on the [available tools](mcp_server.md#available-tools-and-capabilities).

```plaintext
What version of the GitLab MCP server am I connected to?

Get details for issue 1 in project gitlab-org/gitlab
```

{{< alert type="warning" >}}

You are responsible for guarding against prompt injection when using these tools. Exercise extreme caution or use MCP tools only on GitLab objects that you trust.

{{< /alert >}}

## Connect Claude Desktop to a GitLab MCP server

Prerequisites:

- You've installed [Node.js](https://nodejs.org/en/download) version 20 or later.
- Node.js is available globally in the `PATH` environment variable (`which -a node`).

To configure the GitLab MCP server in Claude Desktop:

1. Open Claude Desktop.
1. Edit the configuration file. You can do either of the following:
   - In Claude Desktop, go to **Settings** > **Developer** > **Edit Config**.
   - On macOS, open the `~/Library/Application Support/Claude/claude_desktop_config.json` file.
1. Add this entry for the `GitLab` MCP server, editing as needed:
   - For the `"command":` parameter, if `npx` is installed locally instead of globally, provide the full path to `npx`.
   - Replace `<gitlab.example.com>` with:
     - On GitLab Self-Managed, your GitLab instance URL.
     - On GitLab.com, `GitLab.com`.
   - The `--static-oauth-client-metadata` parameter is mandatory for the `mcp-remote` module to set the OAuth scope to `mcp` as expected by the GitLab server.

   ```json
   {
     "mcpServers": {
       "GitLab": {
         "command": "npx",
         "args": [
           "-y",
           "mcp-remote",
           "https://<gitlab.example.com>/api/v4/mcp",
           "--static-oauth-client-metadata",
           "{\"scope\": \"mcp\"}"
         ]
       }
     }
   }
   ```

1. Save the configuration and restart Claude Desktop.
1. On first connect, Claude Desktop opens a browser window for OAuth. Review and approve the request.
1. Go to **Settings** > **Developer** and verify the new GitLab MCP configuration.
1. Go to **Settings** > **Connectors** and inspect the connected GitLab MCP Server.

You can now start a new chat and ask a question about the MCP server version, a GitLab issue, or merge request depending on the [available tools](mcp_server.md#available-tools-and-capabilities).

```plaintext
What version of the GitLab MCP server am I connected to?

Get details for issue 1 in project gitlab-org/gitlab
```

{{< alert type="warning" >}}

You are responsible for guarding against prompt injection when using these tools. Exercise extreme caution or use MCP tools only on GitLab objects that you trust.

{{< /alert >}}

## Available tools and capabilities

The GitLab MCP server provides the following capabilities.
For more information, see [epic 18413](https://gitlab.com/groups/gitlab-org/-/epics/18413).

### `get_mcp_server_version`

Returns the current version of the GitLab MCP server.

Example:

```plaintext
What version of the GitLab MCP server am I connected to?
```

### `get_issue`

Retrieves detailed information about a specific GitLab issue.

| Parameter    | Required | Description |
|--------------|----------|-------------|
| `project_id` | Yes      | ID or URL-encoded path of the project |
| `issue_iid`  | Yes      | Internal ID of the issue |

Example:

```plaintext
Get details for issue 42 in project 123
```

### `create_issue`

Creates a new issue in a GitLab project.

| Parameter     | Required | Description |
|---------------|----------|-------------|
| `project_id`  | Yes      | ID or URL-encoded path of the project |
| `title`       | Yes      | Title of the issue |
| `description` | No       | Description of the issue |

Example:

```plaintext
Create a new issue titled "Fix login bug" in project 123 with description
"Users cannot log in with special characters in password"
```

### `get_merge_request`

Retrieves detailed information about a specific GitLab merge request.

| Parameter           | Required | Description |
|---------------------|----------|-------------|
| `project_id`        | Yes      | ID or URL-encoded path of the project |
| `merge_request_iid` | Yes      | Internal ID of the merge request |

Example:

```plaintext
Get details for merge request 15 in project gitlab-org/gitlab
```

### `get_merge_request_commits`

Retrieves the list of commits in a specific merge request.

| Parameter           | Required | Description |
|---------------------|----------|-------------|
| `project_id`        | Yes      | ID or URL-encoded path of the project |
| `merge_request_iid` | Yes      | Internal ID of the merge request |

Example:

```plaintext
Show me all commits in merge request 42 from project 123
```

### `get_merge_request_changes`

Retrieves the file changes (diffs) for a specific merge request.

| Parameter           | Required | Description |
|---------------------|----------|-------------|
| `project_id`        | Yes      | ID or URL-encoded path of the project |
| `merge_request_iid` | Yes      | Internal ID of the merge request |

Example:

```plaintext
What files were changed in merge request 25 in the gitlab project?
```

### `get_pipeline_jobs`

Retrieves the jobs for a specific CI/CD pipeline.

| Parameter     | Required | Description |
|---------------|----------|-------------|
| `project_id`  | Yes      | ID or URL-encoded path of the project |
| `pipeline_id` | Yes      | ID of the pipeline |

Example:

```plaintext
Show me all jobs in pipeline 12345 for project gitlab-org/gitlab
```

### `get_merge_request_pipelines_service`

Retrieves the pipelines for a specific merge request.

| Parameter           | Required | Description |
|---------------------|----------|-------------|
| `project_id`        | Yes      | ID or URL-encoded path of the project |
| `merge_request_iid` | Yes      | Internal ID of the merge request |

Example:

```plaintext
Show me all pipelines for merge request 42 in project gitlab-org/gitlab
```

### `gitlab_search`

Searches for a term across the entire GitLab instance with the search API.

| Parameter | Required | Description |
|-----------|----------|-------------|
| `search`  | Yes      | Search term |
| `scope`   | Yes      | Search scope (for example, `issues`, `merge_requests`, or `projects`) |

Example:

```plaintext
Search issues for "flaky test" across GitLab
```

### `create_merge_request`

Creates a merge request in a project.

| Parameter              | Required | Description |
|------------------------|----------|-------------|
| `project_id`           | Yes      | ID or URL-encoded path of the project |
| `source_branch`        | Yes      | Name of the branch to merge from |
| `target_branch`        | Yes      | Name of the branch to merge into |
| `title`                | Yes      | Title of the merge request |
| `description`          | No       | Description text |
| `remove_source_branch` | No       | Delete the source branch on merge (default is `false`) |
| `squash`               | No       | Squash commits on merge (default is `false`) |

Example:

```plaintext
Create a merge request in project gitlab-org/gitlab titled "Bug fix broken specs"
from branch "fix/specs-broken" into "master" and enable squash
```

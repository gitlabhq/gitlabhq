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

- Install Node.js version 20 or later.

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

You can now start a new chat and ask a question depending on the available tools.

{{< alert type="warning" >}}

You're responsible for guarding against prompt injection when you use these tools.
Exercise extreme caution or use MCP tools only on GitLab objects you trust.

{{< /alert >}}

## Connect Claude Desktop to a GitLab MCP server

Prerequisites:

- Install Node.js version 20 or later.
- Ensure Node.js is available globally in the `PATH` environment variable (`which -a node`).

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

You can now start a new chat and ask a question depending on the available tools.

{{< alert type="warning" >}}

You're responsible for guarding against prompt injection when you use these tools.
Exercise extreme caution or use MCP tools only on GitLab objects you trust.

{{< /alert >}}

## Available tools

The GitLab MCP server provides the following tools.

### `get_mcp_server_version`

Returns the current version of the GitLab MCP server.

Example:

```plaintext
What version of the GitLab MCP server am I connected to?
```

### `create_issue`

Creates a new issue in a GitLab project.

| Parameter      | Type    | Required | Description |
|----------------|---------|----------|-------------|
| `id`           | string  | Yes      | ID or URL-encoded path of the project. |
| `title`        | string  | Yes      | Title of the issue. |
| `description`  | string  | No       | Description of the issue. |
| `assignee_ids` | array   | No       | IDs of assigned users. |
| `milestone_id` | integer | No       | ID of the milestone. |
| `labels`       | string  | No       | Comma-separated list of label names. |
| `confidential` | boolean | No       | Sets the issue to confidential. Default is `false`. |
| `epic_id`      | integer | No       | ID of the linked epic. |

Example:

```plaintext
Create a new issue titled "Fix login bug" in project 123 with description
"Users cannot log in with special characters in password"
```

### `get_issue`

Retrieves detailed information about a specific GitLab issue.

| Parameter   | Type    | Required | Description |
|-------------|---------|----------|-------------|
| `id`        | string  | Yes      | ID or URL-encoded path of the project. |
| `issue_iid` | integer | Yes      | Internal ID of the issue. |

Example:

```plaintext
Get details for issue 42 in project 123
```

### `create_merge_request`

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/571243) in GitLab 18.5.

{{< /history >}}

Creates a merge request in a project.

| Parameter           | Type    | Required | Description |
|---------------------|---------|----------|-------------|
| `id`                | string  | Yes      | ID or URL-encoded path of the project. |
| `title`             | string  | Yes      | Title of the merge request. |
| `source_branch`     | string  | Yes      | Name of the source branch. |
| `target_branch`     | string  | Yes      | Name of the target branch. |
| `target_project_id` | integer | No       | ID of the target project. |

Example:

```plaintext
Create a merge request in project gitlab-org/gitlab titled "Bug fix broken specs"
from branch "fix/specs-broken" into "master" and enable squash
```

### `get_merge_request`

Retrieves detailed information about a specific GitLab merge request.

| Parameter           | Type    | Required | Description |
|---------------------|---------|----------|-------------|
| `id`                | string  | Yes      | ID or URL-encoded path of the project. |
| `merge_request_iid` | integer | Yes      | Internal ID of the merge request. |

Example:

```plaintext
Get details for merge request 15 in project gitlab-org/gitlab
```

### `get_merge_request_commits`

Retrieves the list of commits in a specific merge request.

| Parameter           | Type    | Required | Description |
|---------------------|---------|----------|-------------|
| `id`                | string  | Yes      | ID or URL-encoded path of the project. |
| `merge_request_iid` | integer | Yes      | Internal ID of the merge request. |
| `per_page`          | integer | No       | Number of commits per page. |
| `page`              | integer | No       | Current page number. |

Example:

```plaintext
Show me all commits in merge request 42 from project 123
```

### `get_merge_request_diffs`

Retrieves the diffs for a specific merge request.

| Parameter           | Type    | Required | Description |
|---------------------|---------|----------|-------------|
| `id`                | string  | Yes      | ID or URL-encoded path of the project. |
| `merge_request_iid` | integer | Yes      | Internal ID of the merge request. |
| `per_page`          | integer | No       | Number of diffs per page. |
| `page`              | integer | No       | Current page number. |

Example:

```plaintext
What files were changed in merge request 25 in the gitlab project?
```

### `get_merge_request_pipelines`

Retrieves the pipelines for a specific merge request.

| Parameter           | Type    | Required | Description |
|---------------------|---------|----------|-------------|
| `id`                | string  | Yes      | ID or URL-encoded path of the project. |
| `merge_request_iid` | integer | Yes      | Internal ID of the merge request. |

Example:

```plaintext
Show me all pipelines for merge request 42 in project gitlab-org/gitlab
```

### `get_pipeline_jobs`

Retrieves the jobs for a specific CI/CD pipeline.

| Parameter     | Type    | Required | Description |
|---------------|---------|----------|-------------|
| `id`          | string  | Yes      | ID or URL-encoded path of the project. |
| `pipeline_id` | integer | Yes      | ID of the pipeline. |
| `per_page`    | integer | No       | Number of jobs per page. |
| `page`        | integer | No       | Current page number. |

Example:

```plaintext
Show me all jobs in pipeline 12345 for project gitlab-org/gitlab
```

### `gitlab_search`

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/566143) in GitLab 18.4.

{{< /history >}}

Searches for a term across the entire GitLab instance with the search API.
This tool is available only for global search.

| Parameter      | Type    | Required | Description |
|----------------|---------|----------|-------------|
| `scope`        | string  | Yes      | Search scope (for example, `issues`, `merge_requests`, or `projects`). |
| `search`       | string  | Yes      | Search term. |
| `state`        | string  | No       | State of search results. |
| `confidential` | boolean | No       | Filters results by confidentiality. Default is `false`. |
| `per_page`     | integer | No       | Number of results per page. |
| `page`         | integer | No       | Current page number. |
| `fields`       | string  | No       | Comma-separated list of fields you want to search. |

Example:

```plaintext
Search issues for "flaky test" across GitLab
```

### `semantic_code_search`

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/569624) in GitLab 18.5 [with a flag](../../../administration/feature_flags/_index.md) named `code_snippet_search_graphqlapi`. Disabled by default.
- Support for project path [added](https://gitlab.com/gitlab-org/gitlab/-/issues/575234) in GitLab 18.6.

{{< /history >}}

{{< alert type="flag" >}}

The availability of this feature is controlled by a feature flag.
For more information, see the history.
This feature is available for testing, but not ready for production use.

{{< /alert >}}

Searches for relevant code snippets in a project.

| Parameter        | Type    | Required | Description |
|------------------|---------|----------|-------------|
| `semantic_query` | string  | Yes      | Search query for the code. |
| `project_id`     | string  | Yes      | ID or path of the project. |
| `directory_path` | string  | No       | Path of the directory (for example, `app/services/`). |
| `knn`            | integer | No       | Number of nearest neighbors used to find similar code snippets. Default is `64`. |
| `limit`          | integer | No       | Maximum number of results to return. Default is `20`. |

Example:

```plaintext
How are authorizations managed in this project?
```

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

- Introduced in GitLab 18.3 [with two flags](../../../administration/feature_flags/_index.md) named `mcp_server` and `oauth_dynamic_client_generation`. Disabled by default.

{{< /history >}}

{{< alert type="flag" >}}

The availability of this feature is controlled by a feature flag.
For more information, see the history.
This feature is available for testing, but not ready for production use.

{{< /alert >}}

The GitLab [Model Context Protocol](https://modelcontextprotocol.io/) (MCP) server enables AI tools
and applications to connect to your GitLab instance securely. After you configure the MCP server,
AI assistants like Claude Desktop, Cursor, and other MCP-compatible tools can access your GitLab data,
and perform actions on your behalf.

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

## Connect Cursor to a GitLab MCP server

Prerequisites:

- You've installed [Node.js](https://nodejs.org/en/download) version 18 or later.

To do this:

1. Open Cursor.
1. In Cursor, go to **Settings** > **Cursor Settings** > **Tools & Integrations**.
1. Under **MCP Tools**, select `New MCP Server`.
1. Add this definition to the `mcpServers` key, editing the value of `mcp-remote` as needed:

   ```json
   {
     "mcpServers": {
       "GitLab": {
         # If npx is installed locally, not globally, provide the full path
         "command": "npx",
         "args": [
           "mcp-remote",
           "https://your-gitlab-instance.com/api/v4/mcp"
         ]
       }
     }
   }
   ```

1. Save the file, and wait for your browser to open the OAuth authorization page.
1. In your browser, approve the authorization request.
1. The MCP server should be available within Cursor.

{{< alert type="warning" >}}

You are responsible for guarding against prompt injection when using these tools. Exercise extreme caution or use MCP tools only on GitLab objects that you trust.

{{< /alert >}}

## Available tools and capabilities

The GitLab MCP server provides these capabilities. GitLab team members can view more information about the development of this feature
in this confidential epic: `https://gitlab.com/groups/gitlab-org/-/epics/18413`

### `get_mcp_server_version`

Returns the current version of the GitLab MCP server.

**Parameters**: None

**Example usage in AI tool**:

```plaintext
What version of the GitLab MCP server am I connected to?
```

### `get_issue`

Retrieves detailed information about a specific GitLab issue.

**Parameters**:

- `project_id` (required): The ID or URL-encoded path of the project
- `issue_iid` (required): The internal ID of the issue

**Example usage in AI tool**:

```plaintext
Get details for issue 42 in project 123
```

### `create_issue`

Creates a new issue in a GitLab project.

**Parameters**:

- `project_id` (required): The ID or URL-encoded path of the project
- `title` (required): The title of the issue
- `description` (optional): The description of the issue

**Example usage in AI tool**:

```plaintext
Create a new issue titled "Fix login bug" in project 123 with description "Users cannot log in with special characters in password"
```

### `get_merge_request`

Retrieves detailed information about a specific GitLab merge request.

**Parameters**:

- `project_id` (required): The ID or URL-encoded path of the project
- `merge_request_iid` (required): The internal ID of the merge request

**Example usage in AI tool**:

```plaintext
Get details for merge request 15 in project gitlab-org/gitlab
```

### `get_merge_request_commits`

Retrieves the list of commits in a specific merge request.

**Parameters**:

- `project_id` (required): The ID or URL-encoded path of the project
- `merge_request_iid` (required): The internal ID of the merge request

**Example usage in AI tool**:

```plaintext
Show me all commits in merge request 42 from project 123
```

### `get_merge_request_changes`

Retrieves the file changes (diffs) for a specific merge request.

**Parameters**:

- `project_id` (required): The ID or URL-encoded path of the project
- `merge_request_iid` (required): The internal ID of the merge request

**Example usage in AI tool**:

```plaintext
What files were changed in merge request 25 in the gitlab project?
```

### `get_pipeline_jobs`

Retrieves the jobs for a specific CI/CD pipeline.

**Parameters**:

- `project_id` (required): The ID or URL-encoded path of the project
- `pipeline_id` (required): The ID of the pipeline

**Example usage in AI tool**:

```plaintext
Show me all jobs in pipeline 12345 for project gitlab-org/gitlab
```

### `get_merge_request_pipelines_service`

Retrieves the pipelines for a specific merge request.

**Parameters**:

- `project_id` (required): The ID or URL-encoded path of the project
- `merge_request_iid` (required): The internal ID of the merge request

**Example usage in AI tool**:

```plaintext
Show me all pipelines for merge request 42 in project gitlab-org/gitlab
```

## Feedback

This feature is experimental. Your feedback is valuable in helping us to improve it. Share your experiences, suggestions, or issues in [issue 561564](https://gitlab.com/gitlab-org/gitlab/-/issues/561564).

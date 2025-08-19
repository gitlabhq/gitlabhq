---
stage: Developer Experience
group: API
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: Describes Model Context Protocol and how to use it
title: Use Model Context Protocol with AI-native features
---

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Status: Experiment
- Available on GitLab Duo with self-hosted models: Not supported

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/519938) in GitLab 18.1 [with a flag](../../../administration/feature_flags/_index.md) named `duo_workflow_mcp_support`. Disabled by default.
- [Enabled on GitLab.com, GitLab Self-Managed, and GitLab Dedicated](https://gitlab.com/gitlab-org/gitlab/-/issues/545956) in GitLab 18.2. Feature flag `duo_workflow_mcp_support` removed.

{{< /history >}}

The Model Context Protocol (MCP) provides a standardized way for GitLab Duo features
to securely connect to different external data sources and tools.

The following features can act as MCP clients, and connect to and run
external tools from MCP servers:

- [GitLab Duo Agentic Chat](../../../user/gitlab_duo_chat/agentic_chat.md)
- The [software development flow](../../../user/duo_agent_platform/flows/software_development.md)

This connectivity means these features can now use context and information external to GitLab to
generate more powerful answers for customers.

To use a feature with MCP:

- Turn on MCP for your group.
- Configure the MCP servers you want the feature to connect to.

For a click-through demo, see [Duo Agent Platform - MCP integration](https://gitlab.navattic.com/mcp). <!-- Demo published on 2025-08-05 -->

## Prerequisites

Before using a GitLab Duo feature with MCP, you must:

- Install [Visual Studio Code](https://code.visualstudio.com/download) (VS Code).
- Set up the [GitLab Workflow extension for VS Code](https://marketplace.visualstudio.com/items?itemName=GitLab.gitlab-workflow#setup). 
  - MCP support requires version 6.28.2 and later.
  - Workspace and user configuration features require version 6.35.6 and later.

- Meet the prerequisites required for:

  - [GitLab Duo Chat (Agentic)](../../../user/gitlab_duo_chat/agentic_chat.md#use-gitlab-duo-chat-in-vs-code).
  - [Software development flow](../../../user/duo_agent_platform/flows/software_development.md#prerequisites).

## Turn on MCP for your group

To turn MCP on or off for your group:

1. On the left sidebar, select **Search or go to** and find your group.
1. Select **Settings > GitLab Duo**.
1. Select **Change configuration**.
1. Under **Model Context Protocol**, select or clear the
   **Turn on Model Context Protocol (MCP) support** checkbox.
1. Select **Save changes**.

## Configure MCP servers

To integrate MCP with the Language Server, set up workspace configuration, user configuration, or both.
The GitLab Language Server loads and merges the configuration files.

### Version compatibility

| GitLab Workflow extension version | MCP features available |
|-----------------------------------|------------------------|
| 6.28.2 - 6.35.5  | Basic MCP support, with no workspace or user configuration |
| 6.35.6 and later | Full MCP support, including workspace and user configuration |

### Create workspace configuration

Workspace configuration applies to this project only, and overrides any user configuration for the
same server.

To set up workspace configuration:

1. In your project workspace, create the file `<workspace>/.gitlab/duo/mcp.json`.
1. Using the [configuration format](#configuration-format), add information about the MCP servers
   your feature connects to.
1. Save the file.

### Create user configuration

User configuration settings are good for personal tools and commonly-used servers. They apply to all
workspaces, but any workspace settings for the same server override the user configuration.

To set up user configuration:

1. In VS Code, open the Command Palette by pressing
   <kbd>Control</kbd>+<kbd>Shift</kbd>+<kbd>P</kbd> or
   </kbd>Command</kbd>+<kbd>Shift</kbd>+<kbd>P</kbd>.
1. Run the command `GitLab MCP: Open User Settings (JSON)` to create and open the user configuration file.
1. Using the [configuration format](#configuration-format), add information about the MCP servers
   your feature connects to.
1. Save the file.

Alternatively, manually create the file in this location:

- Windows: `C:\Users\<username>\AppData\Roaming\GitLab\duo\mcp.json`
- All other operating systems: `~/.gitlab/duo/mcp.json`

### Configuration format

Both configuration files use the same JSON format:

```json
{
  "mcpServers": {
    "server-name": {
      "command": "path/to/server",
      "args": ["--arg1", "value1"],
      "env": {
        "ENV_VAR": "value"
      }
    },
    "http-server": {
      "url": "http://localhost:3000/mcp"
    }
  }
}
```

### Example MCP server configurations

Use the following code examples to help you create your MCP server configuration file.

For more information and examples, see the [MCP example servers documentation](https://modelcontextprotocol.io/examples).
Other example servers are [Smithery.ai](https://smithery.ai/) and [Awesome MCP Servers](https://mcpservers.org/).

#### Local server

```json
{
  "mcpServers": {
    "enterprise-data-v2": {
      "command": "node",
      "args": ["src/server.js"],
      "cwd": "</path/to/your-mcp-server>"
    }
  }
}
```

#### Remote server

```json
{
  "mcpServers": {
    "aws-knowledge": {
      "command": "npx",
      "args": [
        "mcp-remote",
        "https://knowledge-mcp.global.api.aws"
      ]
    }
  }
}
```

#### HTTP server

```json
{
  "mcpServers": {
    "local-http-server": {
      "url": "http://localhost:3000/mcp"
    }
  }
}
```

## Use GitLab Duo features with MCP

When a GitLab Duo feature wants to call an external tool to answer
the question you have asked, you must review the tool before
the feature can use that tool:

1. Open VS Code.
1. On the left sidebar, select **GitLab Duo Agent Platform (Beta)** ({{< icon name="duo-agentic-chat" >}}).
1. Select the **Chat** or **Flows** tab.
1. In the text box, enter a question or specify a code task.
1. Submit the question or code task.
1. The **Tool Approval Required** dialog appears.

   You must review a tool every time a GitLab Duo feature tries to connect
   to that tool, even if you have previously reviewed that tool.

1. Approve or deny the tool:

   - If you approve the tool, the feature connects to the tool and generates an answer.

   - Optional: For Agentic Chat, if you deny the tool, the **Provide Rejection Reason**
     dialog appears. Enter a rejection reason into the text box, and select
     **Submit Rejection**.

## Feedback

This feature is experimental. Your feedback is valuable in helping us
to improve it. Share your experiences, suggestions, or issues in
[issue 552164](https://gitlab.com/gitlab-org/gitlab/-/issues/552164).

## Related topics

- [Get started with the Model Context Protocol](https://modelcontextprotocol.io/introduction)
- [Demo - Agentic Chat MCP Tool Call Approval](https://www.youtube.com/watch?v=_cHoTmG8Yj8)

## Troubleshooting

### `Error starting server filesystem: Error: spawn ... ENOENT`

This error occurs when you specify a command using a relative path (like `node` instead of `/usr/bin/node`), and that command cannot be found in the `PATH` environment variable that was passed to the GitLab Language Server.

{{< alert type="note" >}}

Improvements to resolving `PATH` are being planned in [issue 1345](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/issues/1345).

{{< /alert >}}

### Troubleshooting MCP in VS Code

For troubleshooting information, see [troubleshooting the GitLab Workflow extension for VS Code](../../../editor_extensions/visual_studio_code/troubleshooting.md).

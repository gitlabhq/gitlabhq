---
stage: AI-powered
group: AI Framework
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: Describes Model Context Protocol and how to use it
title: GitLab MCP clients
---

{{< details >}}

- Tier: Premium, Ultimate
- Add-on: GitLab Duo Core, Pro, or Enterprise
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Status: Beta

{{< /details >}}

{{< collapsible title="Model information" >}}

- Available on GitLab Duo with self-hosted models: Not supported

{{< /collapsible >}}

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/519938) in GitLab 18.1 [with a flag](../../../administration/feature_flags/_index.md) named `duo_workflow_mcp_support`. Disabled by default.
- [Enabled on GitLab.com, GitLab Self-Managed, and GitLab Dedicated](https://gitlab.com/gitlab-org/gitlab/-/issues/545956) in GitLab 18.2. Feature flag `duo_workflow_mcp_support` removed.
- [Changed](https://gitlab.com/gitlab-org/gitlab/-/issues/545956) from experiment to beta in GitLab 18.3.

{{< /history >}}

The Model Context Protocol (MCP) provides a standardized way for GitLab Duo features
to securely connect to different external data sources and tools.

MCP is supported in:

- Visual Studio Code (VS Code) and VSCodium
- JetBrains IDEs

The same MCP configuration file works across all supported IDEs.

The following features can act as MCP clients and connect to external tools from MCP servers:

- [GitLab Duo Chat (Agentic)](../../../user/gitlab_duo_chat/agentic_chat.md)
- The [software development flow](../../../user/duo_agent_platform/flows/software_development.md)

These features can then access external context and information to generate more powerful answers.

To use a feature with MCP:

1. Turn on MCP for your group.
1. Configure the MCP servers you want the feature to connect to.

For a click-through demo, see [Duo Agent Platform - MCP integration](https://gitlab.navattic.com/mcp).
<!-- Demo published on 2025-08-05 -->

## Prerequisites

Before using a GitLab Duo feature with MCP, you must:

- Meet [the prerequisites for the GitLab Duo Agent Platform](../../duo_agent_platform/_index.md#prerequisites).

In addition, for VS Code:

- Install [VSCodium](https://vscodium.com/) or [Visual Studio Code](https://code.visualstudio.com/download) (VS Code).
- Set up the GitLab Workflow extension from the [Open VSX Registry](https://open-vsx.org/extension/GitLab/gitlab-workflow)
  or the [Visual Studio Marketplace](https://marketplace.visualstudio.com/items?itemName=GitLab.gitlab-workflow).
  - MCP support requires version 6.28.2 and later.
  - Workspace and user configuration features require version 6.35.6 and later.

For JetBrains IDEs:

- Install a JetBrains IDE.
- Install and set up the [GitLab Duo plugin for JetBrains IDEs](../../../editor_extensions/jetbrains_ide/setup.md).

## Turn on MCP for your group

To turn MCP on or off for your group:

1. On the left sidebar, select **Search or go to** and find your group. If you've [turned on the new navigation](../../interface_redesign.md#turn-new-navigation-on-or-off), this field is on the top bar.
1. Select **Settings** > **GitLab Duo**.
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
1. Restart your IDE.

### Create user configuration

User configuration settings are good for personal tools and commonly-used servers. They apply to all
workspaces, but any workspace settings for the same server override the user configuration.

To set up user configuration:

1. In VSCodium or VS Code, open the Command Palette by pressing
   <kbd>Control</kbd>+<kbd>Shift</kbd>+<kbd>P</kbd> or
   <kbd>Command</kbd>+<kbd>Shift</kbd>+<kbd>P</kbd>.
1. Run the command `GitLab MCP: Open User Settings (JSON)` to create and open the user configuration file.
1. Using the [configuration format](#configuration-format), add information about the MCP servers
   your feature connects to.
1. Save the file.
1. Restart your IDE.

For JetBrains IDEs, or to manually create the file in VS Code, use this location:

- Windows: `C:\Users\<username>\AppData\Roaming\GitLab\duo\mcp.json`
- All other operating systems: `~/.gitlab/duo/mcp.json`

### Configuration format

Both configuration files use the same JSON format:

```json
{
  "mcpServers": {
    "server-name": {
      "type": "stdio",
      "command": "path/to/server",
      "args": ["--arg1", "value1"],
      "env": {
        "ENV_VAR": "value"
      }
    },
    "http-server": {
      "type": "http",
      "url": "http://localhost:3000/mcp"
    },
    "sse-server": {
      "type": "sse",
      "url": "http://localhost:3000/mcp/sse"
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
      "type": "stdio",
      "command": "node",
      "args": ["src/server.js"],
      "cwd": "</path/to/your-mcp-server>"
    }
  }
}
```

#### Remote server with `mcp-remote`

```json
{
  "mcpServers": {
    "aws-knowledge": {
      "type": "stdio",
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
      "type": "http",
      "url": "http://localhost:3000/mcp"
    }
  }
}
```

#### SSE server

```json
{
  "mcpServers": {
    "remote-sse-server": {
      "type": "sse",
      "url": "http://public.domain:3000/mcp/sse"
    }
  }
}
```

## Use GitLab Duo features with MCP

{{< history >}}

- Approving external tools for the entire session [added](https://gitlab.com/gitlab-org/gitlab/-/issues/556045) in GitLab 18.4.

{{< /history >}}

When a GitLab Duo feature calls an external tool to answer a question,
you must review that tool unless you've approved it for the entire session:

1. Open VS Code.
1. On the left sidebar, select **GitLab Duo Agent Platform (Beta)** ({{< icon name="duo-agentic-chat" >}}).
1. Select the **Chat** or **Flows** tab.
1. In the text box, enter a question or specify a code task.
1. Submit the question or code task.
1. The **Tool Approval Required** dialog appears in these cases:

   - GitLab Duo is calling that tool for the first time in your session.
   - You have not approved that tool for the entire session.

1. Approve or deny the tool:

   - If you approve the tool, the feature connects to the tool and generates an answer.
     - Optional. To approve the tool for the entire session,
       from the **Approve** dropdown list, select **Approve for Session**.

       You can approve only MCP server-provided tools for the session. You cannot
       approve terminal or CLI commands.

   - For Chat, if you deny the tool, the **Provide Rejection Reason** dialog appears.
     Enter a rejection reason, then select **Submit Rejection**.

## Related topics

- [Get started with the Model Context Protocol](https://modelcontextprotocol.io/introduction)
- [Demo - Agentic Chat MCP Tool Call Approval](https://www.youtube.com/watch?v=_cHoTmG8Yj8)

## Troubleshooting

### `Error starting server filesystem: Error: spawn ... ENOENT`

This error occurs when you specify a command using a relative path (like `node` instead of `/usr/bin/node`), and that command cannot be found in the `PATH` environment variable that was passed to the GitLab Language Server.

Improvements to resolving `PATH` are tracked in [issue 1345](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/issues/1345).

### Troubleshooting MCP in VS Code

For troubleshooting information, see [troubleshooting the GitLab Workflow extension for VS Code](../../../editor_extensions/visual_studio_code/troubleshooting.md).

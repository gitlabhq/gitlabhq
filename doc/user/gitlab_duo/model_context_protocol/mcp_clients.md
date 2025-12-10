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

- Not available on GitLab Duo with self-hosted models

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

For a click-through demo, see [GitLab Duo Agent Platform - MCP integration](https://gitlab.navattic.com/mcp).
<!-- Demo published on 2025-08-05 -->

## Prerequisites

- Meet the [prerequisites for the GitLab Duo Agent Platform](../../duo_agent_platform/_index.md#prerequisites).

For Visual Studio Code (VS Code) or VSCodium:

- Install [VS Code](https://code.visualstudio.com/download) or [VSCodium](https://vscodium.com/).
- Install and set up the GitLab Workflow extension from the [Open VSX Registry](https://open-vsx.org/extension/GitLab/gitlab-workflow)
  or the [Visual Studio Marketplace](https://marketplace.visualstudio.com/items?itemName=GitLab.gitlab-workflow).
  - For MCP support, install version 6.28.2 and later.
  - For workspace and user configuration, install version 6.35.6 and later.

For JetBrains IDEs:

- Install a JetBrains IDE.
- Install and set up the [GitLab Duo plugin for JetBrains IDEs](../../../editor_extensions/jetbrains_ide/setup.md).

## Turn on MCP for your group

To turn MCP on or off for your group:

1. On the top bar, select **Search or go to** and find your group.
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

Both configuration files use the same JSON format, with the details in the `mcpServers` key:

```json
{
  "mcpServers": {
    "server-name": {
      "type": "stdio",
      "command": "path/to/server",
      "args": ["--arg1", "value1"],
      "env": {
        "ENV_VAR": "value"
      },
      "approvedTools": true
    },
    "http-server": {
      "type": "http",
      "url": "http://localhost:3000/mcp",
      "approvedTools": ["read_file", "search"]
    },
    "sse-server": {
      "type": "sse",
      "url": "http://localhost:3000/mcp/sse"
    }
  }
}
```

{{< alert type="note" >}}

For other MCP clients, the Atlassian documentation uses `mcp.servers` in the sample configuration file.
For GitLab, use `mcpServers` instead.

{{< /alert >}}

### Configure tool approval

By default, in each session you must manually approve every MCP tool from your server.

Instead, you can pre-approve MCP tools in your configuration file to skip manual approval prompts.

To do so, add the `approvedTools` field to any server configuration:

- `"approvedTools": true` - Automatically approve all current and future tools from this server.
- `"approvedTools": ["tool1", "tool2"]` - Approve only the tools you have specified.

If you do not include this field, you must manually approve every tool in the session (this is the default behavior).

{{< alert type="warning" >}}

Only use `"approvedTools": true` for servers you completely trust.

{{< /alert >}}

For example:

```json
{
  "mcpServers": {
    "trusted-server": {
      "type": "stdio",
      "command": "npx",
      "args": ["my-trusted-mcp-server"],
      "approvedTools": true
    },
    "selective-server": {
      "type": "http",
      "url": "http://localhost:3000/mcp",
      "approvedTools": ["read_file", "search"]
    },
    "untrusted-server": {
      "type": "sse",
      "url": "http://example.com/mcp/sse"
    }
  }
}
```

#### How tool approval works

GitLab uses a two-tier approval system for MCP tools:

- Configuration-based approval (permanent): Tools approved in `mcp.json` using the `approvedTools` field.
  These approvals persist across all sessions.
- Session-based approval (temporary): Tools approved during runtime for the current workflow session.
  These approvals are cleared when you close your IDE or end the workflow.

A tool is approved if either condition is met.

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
      "cwd": "</path/to/your-mcp-server>",
      "approvedTools": ["query_database", "fetch_metrics"]
    }
  }
}
```

#### GitLab Knowledge Graph server

The [GitLab Knowledge Graph](https://gitlab-org.gitlab.io/rust/knowledge-graph) provides code intelligence
through MCP. You can approve all tools or specific ones:

```json
{
  "mcpServers": {
    "knowledge-graph": {
      "type": "sse",
      "url": "http://localhost:27495/mcp/sse",
      "approvedTools": true
    }
  }
}
```

Or approve only specific tools:

```json
{
  "mcpServers": {
    "knowledge-graph": {
      "type": "sse",
      "url": "http://localhost:27495/mcp/sse",
      "approvedTools": ["list_projects", "search_codebase_definitions", "get_references", "get_definition"]
    }
  }
}
```

For more information about available tools, see the
[Knowledge Graph MCP tools documentation](https://gitlab-org.gitlab.io/rust/knowledge-graph/mcp/tools/).

#### HTTP server

```json
{
  "mcpServers": {
    "local-http-server": {
      "type": "http",
      "url": "http://localhost:3000/mcp",
      "approvedTools": ["read_file", "write_file"]
    }
  }
}
```

## View the status of MCP servers

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab-vscode-extension/-/work_items/2155) in the GitLab Workflow extension for VS Code 6.55.0.

{{< /history >}}

Prerequisites:

- Have the GitLab Workflow extension for VS Code 6.55.0 or later installed.
- Have at least one MCP server configured in your user or workspace configuration.

To view the status of your configured MCP servers:

1. In VS Code or VSCodium, open the Command Palette:
   - On macOS, press <kbd>Command</kbd>+<kbd>Shift</kbd>+<kbd>P</kbd>.
   - On Windows or Linux, press <kbd>Control</kbd>+<kbd>Shift</kbd>+<kbd>P</kbd>.
1. Type `GitLab: Show MCP Dashboard` and press <kbd>Enter</kbd>.

The MCP dashboard opens in a new editor tab.
Use the dashboard to:

- Verify that your MCP servers are properly configured and running.
- Identify connection issues before you use GitLab Duo features.
- View which tools are available from each server.
- Troubleshoot server configuration problems.

### Open MCP configuration files

To open your MCP configuration files:

1. In VS Code or VSCodium, open the Command Palette:
   - On macOS, press <kbd>Command</kbd>+<kbd>Shift</kbd>+<kbd>P</kbd>.
   - On Windows or Linux, press <kbd>Control</kbd>+<kbd>Shift</kbd>+<kbd>P</kbd>.
1. Open the configuration files:
   - For user configuration, type `GitLab MCP: Open User Settings (JSON)` and press <kbd>Enter</kbd>.
   - For workspace configuration, type `GitLab MCP: Open Workspace Settings (JSON)` and press <kbd>Enter</kbd>.

## Re-authenticate with MCP servers

After you update authentication details in an MCP configuration file, you must re-authenticate
with the related MCP server.

To trigger re-authentication:

- Ask GitLab Duo a question that requires data from that MCP server
  (for example, `What are the issues in my Jira project?` for Atlassian).
  The authentication flow starts automatically.

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

     Chat might take action based on the reason you provide, such as
     suggesting a new approach, or creating an issue.

## Related topics

- [Get started with the Model Context Protocol](https://modelcontextprotocol.io/introduction)
- [Demo - Agentic Chat MCP Tool Call Approval](https://www.youtube.com/watch?v=_cHoTmG8Yj8)

## Troubleshooting

### Delete the MCP authentication cache

GitLab caches MCP authentication locally under `~/.mcp-auth/`.
To prevent false positives while troubleshooting, delete the cache directory:

```shell
rm -rf ~/.mcp-auth/
```

### `Error starting server filesystem: Error: spawn ... ENOENT`

This error occurs when you specify a command using a relative path (like `node` instead of `/usr/bin/node`), and that command cannot be found in the `PATH` environment variable that was passed to the GitLab Language Server.

Improvements to resolving `PATH` are tracked in [issue 1345](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/issues/1345).

### Troubleshooting MCP in VS Code

For troubleshooting information, see [troubleshooting the GitLab Workflow extension for VS Code](../../../editor_extensions/visual_studio_code/troubleshooting.md).

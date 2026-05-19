---
stage: AI-powered
group: AI Framework
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: Describes Model Context Protocol and how to use it
title: GitLab MCP clients
---

{{< details >}}

- Tier: [Free](../../../subscriptions/gitlab_credits.md#for-the-free-tier), Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< collapsible title="Model information" >}}

- Not available on GitLab Duo with self-hosted models

{{< /collapsible >}}

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/519938) in GitLab 18.1 [with a flag](../../../administration/feature_flags/_index.md) named `duo_workflow_mcp_support`. Disabled by default.
- [Enabled on GitLab.com, GitLab Self-Managed, and GitLab Dedicated](https://gitlab.com/gitlab-org/gitlab/-/issues/545956) in GitLab 18.2. Feature flag `duo_workflow_mcp_support` removed.
- [Changed](https://gitlab.com/gitlab-org/gitlab/-/issues/545956) from experiment to beta in GitLab 18.3.
- [Generally available](https://gitlab.com/gitlab-org/gitlab/-/work_items/585273) in GitLab 18.8.
- Available on the Free tier on GitLab.com with GitLab Credits in GitLab 18.10.
- [Introduced](https://gitlab.com/groups/gitlab-org/-/work_items/19716) in GitLab Duo CLI 8.81.0 during the GitLab 18.11 release.

{{< /history >}}

The Model Context Protocol (MCP) provides a standardized way for GitLab Duo features
to securely connect to different external data sources and tools.

MCP is supported in the following environments:

- Visual Studio Code (VS Code) and VSCodium
- JetBrains IDEs
- The command line, through the GitLab Duo CLI

The same MCP configuration file works across all supported IDEs and the GitLab Duo CLI.

The following features can act as MCP clients and connect to external tools from MCP servers:

- [GitLab Duo Agentic Chat](../../gitlab_duo_chat/agentic_chat.md)
- The [Software Development Flow](../../duo_agent_platform/flows/foundational_flows/software_development.md)

These features can then access external context and information to generate more powerful answers.

To use a feature with MCP:

1. Turn on MCP for your group.
1. Configure the MCP servers you want the feature to connect to.

<i class="fa-youtube-play" aria-hidden="true"></i>
For an overview, see [GitLab Duo Chat (agentic) - MCP tool call approval](https://www.youtube.com/watch?v=_cHoTmG8Yj8).
<!-- Video published on 2025-06-24 -->

For a click-through demo, see [GitLab Duo Agent Platform - MCP client](https://gitlab.navattic.com/mcp).
<!-- Demo published on 2025-08-05 -->

## Prerequisites

- Meet the [prerequisites for the GitLab Duo Agent Platform](../../duo_agent_platform/_index.md#prerequisites).
- For Visual Studio Code (VS Code) or VSCodium:
  - Install and set up [GitLab for VS Code](../../../editor_extensions/visual_studio_code/setup.md) 6.35.6 or later.
- For JetBrains IDEs:
  - Install and set up the [GitLab Duo plugin for JetBrains IDEs](../../../editor_extensions/jetbrains_ide/setup.md) 3.14.0 or later.
- For your command line:
  - Meet the [prerequisites for the GitLab Duo CLI](../../gitlab_duo_cli/_index.md#prerequisites).
  - Install and configure the [GitLab Duo CLI](../../gitlab_duo_cli/_index.md#set-up-the-gitlab-duo-cli)
    8.81.0 or later.

For more information about extension support, see [version compatibility](#version-compatibility).

## Allow external MCP tools

Allow the IDE to access external MCP tools in the top-level group where GitLab Duo is configured.

### On GitLab.com

To allow your local environment to access external MCP tools on GitLab.com:

1. In the top bar, select **Search or go to** and find your group.
1. In the left sidebar, select **Settings** > **GitLab Duo**.
1. Select **Change configuration**.
1. Under **External MCP tools**, select the **Allow external MCP tools** checkbox.
1. Select **Save changes**.

### On GitLab Self-Managed

To allow your local environment to access external MCP tools on GitLab Self-Managed:

1. In the top bar, select **Search or go to** and find your group.
1. In the left sidebar, select **Settings** > **General**.
1. Expand **GitLab Duo features**.
1. Under **External MCP tools**, select the **Allow external MCP tools** checkbox.
1. Select **Save changes**.

## Configure MCP servers

To integrate MCP with the Language Server, set up workspace configuration, user configuration, or both.
The GitLab Language Server loads and merges the configuration files.

### Version compatibility

| MCP support | GitLab for VS Code | GitLab Duo plugin <br>for JetBrains IDEs | GitLab Duo CLI |
|------------------------|-----------------------------------|------------------------|------------------------|
| Basic (no workspace or user configuration) | 6.28.2 or later | 3.10.0 or later |  |
| Full (with workspace and user configuration) | 6.35.6 or later | 3.14.0 or later | 8.81.0 or later |

### Create workspace configuration

Workspace configuration applies to this project only, and overrides any user configuration for the
same server.

To set up workspace configuration:

1. In your project workspace, create the file `<workspace>/.gitlab/duo/mcp.json`.
1. Using the [configuration format](#configuration-format), add information about the MCP servers
   your feature connects to.
1. Save the file.
1. Restart your IDE or the GitLab Duo CLI.

### Create user configuration

User configuration settings are good for personal tools and commonly-used servers. They apply to all
workspaces, but any workspace settings for the same server override the user configuration.

To set up user configuration:

1. Create a configuration file:

   {{< tabs >}}

   {{< tab title="VS Code or VSCodium" >}}

   1. In your IDE, open the Command Palette:
      - For macOS, press <kbd>Command</kbd>+<kbd>Shift</kbd>+<kbd>P</kbd>.
      - For Windows or Linux, press <kbd>Control</kbd>+<kbd>Shift</kbd>+<kbd>P</kbd>.
   1. Run the command `GitLab MCP: Open User Settings (JSON)`.

   {{< /tab >}}

   {{< tab title="JetBrains IDEs" >}}

   - Create an `mcp.json` file in your home directory:
     - For Linux or macOS, at `~/.gitlab/duo/mcp.json`.
     - For Windows, at `%APPDATA%\GitLab\duo\mcp.json`.

       For example, `C:\Users\<username>\AppData\Roaming\GitLab\duo\mcp.json`.

   If you have set one of the following environment variables, create the file in a different location:

   - For `GLAB_CONFIG_DIR`, at `$GLAB_CONFIG_DIR/duo/mcp.json`.
   - For `XDG_CONFIG_HOME`, at `$XDG_CONFIG_HOME/gitlab/duo/mcp.json`.

   {{< /tab >}}

   {{< tab title="GitLab Duo CLI" >}}

   - Create an `mcp.json` file in your home directory:
     - For Linux or macOS, at `~/.gitlab/duo/mcp.json`.
     - For Windows, at `%APPDATA%\GitLab\duo\mcp.json`.

       For example, `C:\Users\<username>\AppData\Roaming\GitLab\duo\mcp.json`.

   If you have set one of the following environment variables, create the file in a different location:

   - For `GLAB_CONFIG_DIR`, at `$GLAB_CONFIG_DIR/duo/mcp.json`.
   - For `XDG_CONFIG_HOME`, at `$XDG_CONFIG_HOME/gitlab/duo/mcp.json`.

   {{< /tab >}}
   {{< /tabs >}}

1. Using the [configuration format](#configuration-format), add information about the MCP servers
   your feature connects to.
1. Save the file.
1. Restart your IDE or the GitLab Duo CLI.

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

> [!note]
> For other MCP clients, the Atlassian documentation uses `mcp.servers` in the sample configuration file.
> For GitLab, use `mcpServers` instead.

### Configure tool approval

By default, in each session you must manually approve every MCP tool from your server.

Instead, you can pre-approve MCP tools in your configuration file to skip manual approval prompts.

To do so, add the `approvedTools` field to any server configuration:

- `"approvedTools": true` - Automatically approve all current and future tools from this server.
- `"approvedTools": ["tool1", "tool2"]` - Approve only the tools you have specified.

If you do not include this field, you must manually approve every tool in the session (this is the default behavior).

> [!warning]
> Only use `"approvedTools": true` for servers you completely trust.

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

- [Introduced](https://gitlab.com/gitlab-org/gitlab-vscode-extension/-/work_items/2155) in the GitLab for VS Code extension 6.55.0.

{{< /history >}}

Prerequisites:

- GitLab for VS Code extension 6.55.0 or later.
- At least one MCP server configured in your user or workspace configuration.

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
1. In the left sidebar, select **GitLab Duo Agent Platform** ({{< icon name="duo-agentic-chat" >}}).
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

For troubleshooting information, see [troubleshooting the GitLab for VS Code extension](../../../editor_extensions/visual_studio_code/troubleshooting.md).

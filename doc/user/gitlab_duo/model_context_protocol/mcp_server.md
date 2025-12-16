---
stage: AI-powered
group: AI Framework
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: Connect AI tools to your GitLab instance with the GitLab MCP server.
title: GitLab MCP server
---

{{< details >}}

- Tier: Premium, Ultimate
- Add-on: GitLab Duo Core, Pro, or Enterprise
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Status: Beta

{{< /details >}}

{{< history >}}

- Introduced as an [experiment](../../../policy/development_stages_support.md#experiment) in GitLab 18.3 [with flags](../../../administration/feature_flags/_index.md) named `mcp_server` and `oauth_dynamic_client_registration`. Disabled by default.
- Changed from experiment to [beta](../../../policy/development_stages_support.md#beta) in GitLab 18.6. Feature flags [`mcp_server`](https://gitlab.com/gitlab-org/gitlab/-/issues/556448) and [`oauth_dynamic_client_registration`](https://gitlab.com/gitlab-org/gitlab/-/issues/555942) removed.
- Support for `2025-03-26` and `2025-06-18` MCP protocol specifications [added](https://gitlab.com/gitlab-org/gitlab/-/issues/581459) in GitLab 18.7.

{{< /history >}}

{{< alert type="warning" >}}

To provide feedback on this feature, leave a comment on [issue 561564](https://gitlab.com/gitlab-org/gitlab/-/issues/561564).

{{< /alert >}}

With the GitLab [Model Context Protocol](https://modelcontextprotocol.io/) (MCP) server,
you can securely connect AI tools and applications to your GitLab instance.
AI assistants like Claude Desktop, Claude Code, Cursor, and other MCP-compatible tools
can then access your GitLab data and perform actions on your behalf.

The GitLab MCP server provides a standardized way for AI tools to:

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

For a click-through demo, see [GitLab Duo Agent Platform - GitLab MCP server](https://gitlab.navattic.com/gitlab-mcp-server).
<!-- Demo published on 2025-09-11 -->

## Prerequisites

- Have [GitLab Duo Core](../../gitlab_duo/turn_on_off.md#turn-gitlab-duo-core-on-or-off) and
  [beta and experimental features](../../gitlab_duo/turn_on_off.md#turn-on-beta-and-experimental-features) turned on.

## Connect a client to the GitLab MCP server

The GitLab MCP server supports two transport types:

- **HTTP transport (recommended)**: Direct connection without additional dependencies.
- **stdio transport with `mcp-remote`**: Connection through a proxy (requires Node.js).

Common AI tools support the JSON configuration format for the `mcpServers` key
and provide different methods to configure the GitLab MCP server settings.

### HTTP transport (recommended)

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/577575) in GitLab 18.6.

{{< /history >}}

To configure the GitLab MCP server by using HTTP transport, use this format:

- Replace `<gitlab.example.com>` with:
  - On GitLab Self-Managed, your GitLab instance URL.
  - On GitLab.com, `gitlab.com`.

```json
{
  "mcpServers": {
    "GitLab": {
      "type": "http",
      "url": "https://<gitlab.example.com>/api/v4/mcp"
    }
  }
}
```

### stdio transport with `mcp-remote`

Prerequisites:

- Install Node.js version 20 or later.

To configure the GitLab MCP server by using stdio transport, use this format:

- For the `"command":` parameter, if `npx` is installed locally instead of globally, provide the full path to `npx`.
- Replace `<gitlab.example.com>` with:
  - On GitLab Self-Managed, your GitLab instance URL.
  - On GitLab.com, `gitlab.com`.

```json
{
  "mcpServers": {
    "GitLab": {
      "command": "npx",
      "args": [
        "mcp-remote",
        "https://<gitlab.example.com>/api/v4/mcp"
      ]
    }
  }
}
```

## Connect Cursor to the GitLab MCP server

Cursor uses HTTP transport for direct connection without additional dependencies.
To configure the GitLab MCP server in Cursor:

1. In Cursor, go to **Settings** > **Cursor Settings** > **Tools & MCP**.
1. Under **Installed MCP Servers**, select **New MCP Server**.
1. Add this definition to the `mcpServers` key in the opened `mcp.json` file:
   - Replace `<gitlab.example.com>` with:
     - On GitLab Self-Managed, your GitLab instance URL.
     - On GitLab.com, `gitlab.com`.

   ```json
   {
     "mcpServers": {
       "GitLab": {
          "type": "http",
          "url": "https://<gitlab.example.com>/api/v4/mcp"
       }
     }
   }
   ```

1. Save the file, and wait for your browser to open the OAuth authorization page.

   If this does not happen, close and restart Cursor.
1. In your browser, review and approve the authorization request.

You can now start a new chat and ask a question depending on the [available tools](mcp_server_tools.md).

{{< alert type="warning" >}}

You're responsible for guarding against prompt injection when you use these tools.
Exercise extreme caution or use MCP tools only on GitLab objects you trust.

{{< /alert >}}

## Connect Claude Code to the GitLab MCP server

Claude Code uses HTTP transport for direct connection without additional dependencies.
To configure the GitLab MCP server in Claude Code:

1. In your terminal, add the GitLab MCP server with the CLI:
   - Replace `<gitlab.example.com>` with:
     - On GitLab Self-Managed, your GitLab instance URL.
     - On GitLab.com, `gitlab.com`.

   ```shell
   claude mcp add --transport http GitLab https://<gitlab.example.com>/api/v4/mcp
   ```

1. Start Claude Code:

   ```shell
   claude
   ```

1. Authenticate with the GitLab MCP server:
   - In the chat, type `/mcp`.
   - From the list, select your GitLab server.
   - In your browser, review and approve the authorization request.

1. Optional. To verify the connection, type `/mcp` again.
   Your GitLab server should appear as connected.

You can now start a new chat and ask a question depending on the [available tools](mcp_server_tools.md).

{{< alert type="warning" >}}

You're responsible for guarding against prompt injection when you use these tools.
Exercise extreme caution or use MCP tools only on GitLab objects you trust.

{{< /alert >}}

## Connect Claude Desktop to the GitLab MCP server

Prerequisites:

- Install Node.js version 20 or later.
- Have Node.js available globally in the `PATH` environment variable (`which -a node`).

To configure the GitLab MCP server in Claude Desktop:

1. Open Claude Desktop.
1. Edit the configuration file. You can do either of the following:
   - In Claude Desktop, go to **Settings** > **Developer** > **Edit Config**.
   - On macOS, open the `~/Library/Application Support/Claude/claude_desktop_config.json` file.
1. Add this entry for the GitLab MCP server, editing as needed:
   - For the `"command":` parameter, if `npx` is installed locally instead of globally, provide the full path to `npx`.
   - Replace `<gitlab.example.com>` with:
     - On GitLab Self-Managed, your GitLab instance URL.
     - On GitLab.com, `GitLab.com`.

   ```json
   {
     "mcpServers": {
       "GitLab": {
         "command": "npx",
         "args": [
           "-y",
           "mcp-remote",
           "https://<gitlab.example.com>/api/v4/mcp"
         ]
       }
     }
   }
   ```

1. Save the configuration and restart Claude Desktop.
1. On first connect, Claude Desktop opens a browser window for OAuth. Review and approve the request.
1. Go to **Settings** > **Developer** and verify the new GitLab MCP configuration.
1. Go to **Settings** > **Connectors** and inspect the connected GitLab MCP server.

You can now start a new chat and ask a question depending on the [available tools](mcp_server_tools.md).

{{< alert type="warning" >}}

You're responsible for guarding against prompt injection when you use these tools.
Exercise extreme caution or use MCP tools only on GitLab objects you trust.

{{< /alert >}}

## Connect Gemini Code Assist and Gemini CLI to the GitLab MCP server

Gemini Code Assist and Gemini CLI use HTTP transport
for direct connection without additional dependencies.
To configure the GitLab MCP server in Gemini Code Assist or Gemini CLI:

1. Edit `~/.gemini/settings.json` and add the GitLab MCP server.
   - Replace `<gitlab.example.com>` with:
     - On GitLab Self-Managed, your GitLab instance URL.
     - On GitLab.com, `gitlab.com`.

   ```json
   {
     "mcpServers": {
       "GitLab": {
         "httpUrl": "https://<gitlab.example.com>/api/v4/mcp"
       }
     }
   }
   ```

1. In Gemini Code Assist or Gemini CLI, run the `/mcp auth GitLab` command.

   The OAuth authorization page should appear.
   Otherwise, restart Gemini Code Assist or Gemini CLI.

1. In your browser, review and approve the authorization request.

You can now start a new chat and ask a question depending on the [available tools](mcp_server_tools.md).

{{< alert type="warning" >}}

You're responsible for guarding against prompt injection when you use these tools.
Exercise extreme caution or use MCP tools only on GitLab objects you trust.

{{< /alert >}}

## Connect GitHub Copilot in VS Code to the GitLab MCP server

GitHub Copilot uses HTTP transport for direct connection without additional dependencies.
To configure the GitLab MCP server in GitHub Copilot in VS Code:

1. In VS Code, open the Command Palette:
   - On macOS, press <kbd>Command</kbd>+<kbd>Shift</kbd>+<kbd>P</kbd>.
   - On Windows or Linux, press <kbd>Control</kbd>+<kbd>Shift</kbd>+<kbd>P</kbd>.
1. Type `MCP: Add Server` and press <kbd>Enter</kbd>.
1. For the server type, select **HTTP**.
1. For the server URL, enter `https://<gitlab.example.com>/api/v4/mcp`.
   - Replace `<gitlab.example.com>` with:
     - On GitLab Self-Managed, your GitLab instance URL.
     - On GitLab.com, `gitlab.com`.
1. For the server ID, enter `GitLab`.
1. Save the configuration globally or in the `vscode/mcp.json` workspace.

   The OAuth authorization page should appear.
   Otherwise, open the Command Palette and search for **MCP: List Servers**
   to check the status or restart the server.

1. In your browser, review and approve the authorization request.

You can now start a new chat and ask a question depending on the [available tools](mcp_server_tools.md).

{{< alert type="warning" >}}

You're responsible for guarding against prompt injection when you use these tools.
Exercise extreme caution or use MCP tools only on GitLab objects you trust.

{{< /alert >}}

## Connect Continue in VS Code to the GitLab MCP server

Prerequisites:

- Install Node.js version 20 or later.
- Have Node.js available globally in the `PATH` environment variable (`which -a node`).

To configure the GitLab MCP server in Continue in VS Code:

1. In VS Code, in the Activity Bar, select the Continue extension.
1. Open the settings and select **Tools**.
1. Next to **MCP Servers**, add a new server.
1. Edit the configuration file `.continue/mcpServers/new-mcp-server.yaml`:
   - Replace `<gitlab.example.com>` with:
     - On GitLab Self-Managed, your GitLab instance URL.
     - On GitLab.com, `gitlab.com`.

   ```yaml
   name: GitLab MCP server
   version: 0.0.1
   schema: v1
   mcpServers:
     - name: GitLab MCP server
       type: stdio
       command: npx
       args:
         - mcp-remote
         - https://<gitlab.example.com>/api/v4/mcp
   ```

1. Save the configuration.

   The OAuth authorization page should appear.

1. In your browser, review and approve the authorization request.

You can now start a new chat and ask a question depending on the [available tools](mcp_server_tools.md).

{{< alert type="warning" >}}

You're responsible for guarding against prompt injection when you use these tools.
Exercise extreme caution or use MCP tools only on GitLab objects you trust.

{{< /alert >}}

## Connect OpenAI Codex to the GitLab MCP server

OpenAI Codex uses HTTP transport for direct connection without additional dependencies.
To configure the GitLab MCP server in OpenAI Codex:

1. In your terminal, add the GitLab MCP server with the CLI:
   - Replace `<gitlab.example.com>` with:
     - On GitLab Self-Managed, your GitLab instance URL.
     - On GitLab.com, `gitlab.com`.

  ```shell
  codex mcp add --url "https://<gitlab.example.com>/api/v4/mcp" GitLab
  ```

1. Edit `~/.codex/config.toml` and, in the `[features]` section,
   enable the `rmcp_client` feature flag.

   ```toml
   [features]
   "rmcp_client" = true

   [mcp_servers.GitLab]
   url = "https://<gitlab.example.com>/api/v4/mcp"
   ```

1. Run the login flow and authenticate with the GitLab instance.

   ```shell
   codex mcp login GitLab
   ```

1. In your browser, review and approve the authorization request.

You can now start a new chat and ask a question depending on the [available tools](mcp_server_tools.md).

{{< alert type="warning" >}}

You're responsible for guarding against prompt injection when you use these tools.
Exercise extreme caution or use MCP tools only on GitLab objects you trust.

{{< /alert >}}

## Connect Zed to the GitLab MCP server

Prerequisites:

- Install Node.js version 20 or later.
- Have Node.js available globally in the `PATH` environment variable (`which -a node`).

To configure the GitLab MCP server in Zed:

1. In Zed, open the Command Palette:
   - On macOS, press <kbd>Command</kbd>+<kbd>Shift</kbd>+<kbd>P</kbd>.
   - On Windows or Linux, press <kbd>Control</kbd>+<kbd>Shift</kbd>+<kbd>P</kbd>.
1. Type `agent: open settings` and press <kbd>Enter</kbd>.
1. In the **Model Context Protocol (MCP) Servers** section, select **Add Server**.
1. For the server URL in `args`, use `https://<gitlab.example.com>/api/v4/mcp`.
   - Replace `<gitlab.example.com>` with:
     - On GitLab Self-Managed, your GitLab instance URL.
     - On GitLab.com, `gitlab.com`.

   ```json
   {
     /// The name of your MCP server
     "GitLab": {
       /// The command which runs the MCP server
       "command": "npx",
       /// The arguments to pass to the MCP server
       "args": ["-y","mcp-remote@latest","https://<gitlab.example.com>/api/v4/mcp"],
       /// The environment variables to set
       "env": {}
     }
   }
   ```

1. Save the configuration.

   The OAuth authorization page should appear.
   If not, turn the **GitLab** toggle off and on again.

1. In your browser, review and approve the authorization request.

You can now start a new chat and ask a question depending on the [available tools](mcp_server_tools.md).

{{< alert type="warning" >}}

You're responsible for guarding against prompt injection when you use these tools.
Exercise extreme caution or use MCP tools only on GitLab objects you trust.

{{< /alert >}}

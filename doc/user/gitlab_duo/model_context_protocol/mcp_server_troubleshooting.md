---
stage: AI-powered
group: AI Framework
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: Troubleshoot the GitLab MCP server.
title: Troubleshooting the GitLab MCP server
---

{{< details >}}

- Tier: Premium, Ultimate
- Add-on: GitLab Duo Core, Pro, or Enterprise
- Offering: GitLab.com, GitLab Self-Managed
- Status: Experiment

{{< /details >}}

{{< history >}}

- Introduced in GitLab 18.3 [with flags](../../../administration/feature_flags/_index.md) named `mcp_server` and `oauth_dynamic_client_registration`. Disabled by default.
- [Removed](https://gitlab.com/gitlab-org/gitlab/-/issues/556448) feature flag `mcp_server` in GitLab 18.6.
- [Removed](https://gitlab.com/gitlab-org/gitlab/-/issues/555942) feature flag `oauth_dynamic_client_registration` in GitLab 18.6.

{{< /history >}}

{{< alert type="warning" >}}

To provide feedback on this feature, leave a comment on [issue 561564](https://gitlab.com/gitlab-org/gitlab/-/issues/561564).

{{< /alert >}}

When working with GitLab MCP server, you might encounter issues.

## Troubleshoot the GitLab MCP Server in Cursor

1. In Cursor, to open the Output view, do one of the following:
   - Go to **View** > **Output**.
   - In macOS, press <kbd>Command</kbd>+<kbd>Shift</kbd><kbd>U</kbd>.
   - In Windows or Linux, press <kbd>Control</kbd>+<kbd>Shift</kbd><kbd>U</kbd>.
1. In the Output view, select **MCP:SERVERNAME**. The name depends on the MCP configuration value. The example with `GitLab` results in `MCP: user-GitLab`.
1. When reporting bugs, copy the output into the issue template logs section.

## Troubleshoot the GitLab MCP Server on the CLI with mcp-remote

1. Install [Node.js](https://nodejs.org/en/download) version 20 or later.

1. To test the exact same command as the IDEs and desktop clients:
   1. Extract the MCP configuration.
   1. Assemble the `npx` command string into one line.
   1. Run the command string.

   ```shell
   rm -rf ~/.mcp-auth/mcp-remote*

   npx -y mcp-remote@latest https://gitlab.example.com/api/v4/mcp --static-oauth-client-metadata '{"scope": "mcp"}'
   ```

1. Add the `--debug` parameter to log more verbose output:

   ```shell
   rm -rf ~/.mcp-auth/mcp-remote*

   npx -y mcp-remote@latest https://gitlab.example.com/api/v4/mcp --static-oauth-client-metadata '{"scope": "mcp"}' --debug
   ```

1. Optional. Run the `mcp-remote-client` executable directly.

   ```shell
   rm -rf ~/.mcp-auth/mcp-remote*

   npx -p mcp-remote@latest mcp-remote-client https://gitlab.example.com/api/v4/mcp --static-oauth-client-metadata '{"scope": "mcp"}'
   ```

1. Optional. If you encounter version-specific bugs, pin the version of the `mcp-remote` module to a specific version. For example, use `mcp-remote@0.1.26` to pin the version to `0.1.26`.

   {{< alert type="note" >}}

   For security reasons, you should not pin versions if possible.

   {{< /alert >}}

## Troubleshoot GitLab MCP Server with Claude Desktop

Verify the installed [Node.js](https://nodejs.org/en/download) versions. Claude Desktop requires Node.js version 20 or later.

```shell
for n in $(which -a node); do echo "$n" && $n -v; done
```

## Delete MCP authentication caches

The MCP authentication is heavily cached locally. While troubleshooting, you might encounter false positives. To prevent these, delete the cache directory during troubleshooting:

```shell
rm -rf ~/.mcp-auth/mcp-remote*
```

## Debugging and development tools

[MCP Inspector](https://modelcontextprotocol.io/legacy/tools/inspector) is an interactive
developer tool for testing and debugging MCP servers. To run this tool, use the command
line and access the web interface to inspect the GitLab MCP Server.

```shell
npx -y @modelcontextprotocol/inspector npx
```

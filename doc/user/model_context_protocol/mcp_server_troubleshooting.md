---
stage: Agent Foundations
group: Agent Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: Troubleshoot common issues with the GitLab MCP server.
title: Troubleshooting the GitLab MCP server
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Status: Generally available

{{< /details >}}

When working with the GitLab MCP server, you might encounter the following issues.

## Error: `403 Forbidden`

You might get this error when you start the GitLab MCP server. You might also get this error
when `POST /api/v4/mcp` or `GET /api/v4/mcp` returns `403 Forbidden` after the OAuth flow
completes.

In GitLab 19.4 and earlier, the same issue returns `404 Not Found` instead. Both status codes
share the same causes.

To resolve this issue, make sure you meet the
[prerequisites for the GitLab MCP server](mcp_server.md#prerequisites).

To find the cause, read the message in the response body. Administrators can also check the
`denial_reason` field in the [`mcp.log`](../../administration/logs/_index.md#mcplog) file:

- `MCP server disabled for this instance` (`denial_reason`: `instance_setting_disabled`):
  On GitLab Self-Managed, an administrator
  [turned off](../../administration/settings/visibility_and_access_controls.md#allow-access-to-the-mcp-server)
  the MCP server for the instance.
- `MCP server not enabled for any of your groups` (`denial_reason`: `no_enabled_namespace`):
  On GitLab.com, no top-level group you belong to has the MCP server
  [turned on](../group/access_and_permissions.md#allow-access-to-the-mcp-server).

> [!note]
> `404` errors returned by a REST-backed tool call, for example `404 Project Not Found`,
> appear in the JSON-RPC response body with `isError: true`, and in `mcp.log` with
> `tool_status` set to `not_found`. Other tool call failures also appear in the response
> body with `isError: true`, and in `mcp.log` with a `tool_status` that describes what
> happened.

## Error: `Server's protocol version is not supported: 2025-06-18`

In GitLab 18.6 and earlier, you might get this error when the MCP client library
does not support the GitLab MCP server protocol specification.

To resolve this issue, ask the AI tool provider
to update their client implementation.

## Error: `429 Too Many Requests`

Your MCP client might stop working and report a generic HTTP or connection error, and every request
fails until the rate limit period resets. This happens when a rate limit is exceeded: either the
MCP server rate limit or the authenticated API rate limit, because MCP server requests count against
both. GitLab refuses the request before it reaches the MCP server, so no tool runs. Unlike a
[`rate_limited` tool result](#error-rate_limited-tool-result), this is not a `200 OK` that carries
an error result.

The response is HTTP `429` with content type `text/plain` and, by default, the body `Retry later`.
It is not a JSON-RPC message, so an MCP client cannot read it as an MCP response.

To confirm the cause, check the response headers:

- `RateLimit-Name` identifies which limit was reached. On GitLab Self-Managed, the MCP server limit
  is `throttle_authenticated_mcp`. Any other value means a different limit, such as the general
  authenticated API limit.
- `Retry-After` is the number of seconds to wait before you retry. It is the time remaining in the
  current period, not the full period. Clients should honor it rather than retry immediately.

The response also includes the other
[rate limit headers](../../administration/settings/user_and_ip_rate_limits.md#response-headers).

Before the limit is reached, successful `200 OK` responses already include `RateLimit-Remaining`,
so a client or proxy that reads headers can see the limit approaching.

Administrators can also check the logs:

- A refused request appears in the
  [Workhorse log](../../administration/logs/_index.md#workhorse-logs) with `status` `429` and `uri`
  `/api/v4/mcp`. The entry has no user and no limit name.
- A refused request does not appear in `api_json.log` or
  [`mcp.log`](../../administration/logs/_index.md#mcplog), because it never reaches the API. It also
  does not appear in `auth.log`, unlike some other GitLab rate limits.
- Requests that were counted but allowed appear in
  [`api_json.log`](../../administration/logs/_index.md#api_jsonlog) with a `rate_limit_state` field
  containing `rack_request_mcp:authenticated_mcp:allow`. Use this to identify which users consume
  the limit.

To resolve this issue, wait for the number of seconds in `Retry-After`, then retry.

- On GitLab.com, per-plan limits apply to MCP requests. For the published values, see
  [rate limits](mcp_server.md#rate-limits).
- On GitLab Self-Managed, the limit is disabled by default. If it is enabled, an administrator can
  [raise or disable it](../../administration/settings/user_and_ip_rate_limits.md#enable-authenticated-mcp-server-request-rate-limit).

## Error: `rate_limited` tool result

If you got an HTTP `429 Too Many Requests` response instead, see [`429 Too Many Requests`](#error-429-too-many-requests).

You might get a tool result with `isError: true`, even though the MCP server itself returned `200 OK`.
This happens when a tool call hits a rate limit on the underlying GitLab API endpoint it calls, for
example the search rate limit when a search tool runs.

The MCP server does not return `429 Too Many Requests` for this case. Instead, it follows the Model
Context Protocol specification, which classifies API failures as tool execution errors reported in
the result so a client or language model can read them and self-correct.

The `content` field contains a human-readable message, for example:

```plaintext
Rate limited by search_rate_limit. Retry after 60 seconds.
```

The `structuredContent` field contains machine-readable retry detail:

```json
{
  "error": {
    "type": "rate_limited",
    "retry_after_seconds": 60,
    "limit": "search_rate_limit",
    "message": "This endpoint has been requested too many times. Try again later."
  }
}
```

To resolve this issue, wait and retry the tool call. When you build an MCP client, check
`error.type == "rate_limited"` rather than match on the message text, because the wording can change.
Use `limit` to identify which rate limit was hit, as a single tool call can consume more than one.
Treat `retry_after_seconds` as a safe upper bound rather than an exact wait time, because it is the
full rate limit period rather than the time remaining in the current window.

> [!note]
> `retry_after_seconds` and `limit` are present only when the endpoint that GitLab called provided
> them. Always handle a response where these fields are absent. Administrators can change rate limits
> for individual endpoints, so actual values vary by instance.

## Error: `403 Forbidden` tool result from `start_duo_session`

You might get an error that states `403 Forbidden` when you call the `start_duo_session` tool.
The MCP server returns `200 OK`, and the tool result has `isError: true` with the following
message in the `content` field:

```plaintext
403 Forbidden
```

This issue occurs when you cannot run the flow in the project. `start_duo_session` always
starts the flow as a session that runs in a CI job, and you must have permission to run
that flow in the project.

To resolve this issue, do one of the following:

- If you do not have access to GitLab Duo Agent Platform, meet the
  [prerequisites for GitLab Duo Agent Platform](../duo_agent_platform/_index.md#prerequisites).
- If you have the Reporter role or lower in the project, ask a project Owner or Maintainer
  for at least the Developer role.
- If foundational flows are turned off, ask a project Maintainer or Owner, or a top-level
  group Owner, to
  [turn on foundational flows](../duo_agent_platform/flows/foundational_flows/_index.md#turn-foundational-flows-on-or-off).
- If the flow is in beta, ask a top-level group Owner to
  [turn on beta and experimental features](../duo_agent_platform/turn_on_off.md#turn-on-beta-and-experimental-features).

If you do not use GitLab Duo Agent Platform, you can hide its tools from your MCP client.
If your client supports custom headers, send the `X-Gitlab-Enabled-Mcp-Server-Toolsets` header
with a list that does not include `duo_agent_platform`. For more information, see
[select tool groups (toolsets)](mcp_server.md#select-tool-groups-toolsets).

## Troubleshoot the GitLab MCP Server in Cursor

1. In Cursor, to open the Output view, do one of the following:
   - Go to **View** > **Output**.
   - In macOS, press <kbd>Command</kbd>+<kbd>Shift</kbd>+<kbd>U</kbd>.
   - In Windows or Linux, press <kbd>Control</kbd>+<kbd>Shift</kbd>+<kbd>U</kbd>.
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

   > [!note]
   > For security reasons, you should not pin versions if possible.

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

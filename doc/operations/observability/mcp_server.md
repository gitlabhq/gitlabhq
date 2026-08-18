---
stage: none
group: Embody
info: This page is owned by <https://handbook.gitlab.com/handbook/engineering/embody-team/>
description: Query GitLab Observability data from AI assistants with the Model Context Protocol server.
ignore_in_report: true
title: Observability MCP server
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com
- Status: Experiment

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/248200) in GitLab 19.3 as an [experiment](../../policy/development_stages_support.md#experiment).

{{< /history >}}

GitLab Observability provides a [Model Context Protocol (MCP)](https://modelcontextprotocol.io)
server so you can query your observability data from AI assistants and agents
using natural language.

After you connect, an MCP-capable client can ask questions about your telemetry
and get answers backed by your own data. Supported clients include Cursor,
Claude (Claude Code and Claude Desktop), VS Code, and Codex. For example:

- Which service has the highest error rate in the last hour?
- Show me error logs for the checkout service.
- What's the p99 latency for the payment service today?
- List the services that are reporting data.

The MCP server can query metrics, traces, logs, alerts, dashboards, and services
in your GitLab Observability instance.

## Prerequisites

- Observability must be enabled for your group or personal project.
  For setup instructions, see
  [Set up Observability on GitLab.com](setup_gitlab_com.md).
- For a group, you must have the Developer, Maintainer, or Owner role. For a
  personal project, you must have the Owner role.
- You need an MCP client that supports remote HTTP servers.

## Get your API key

The MCP server has no standing credentials of its own. Each user authenticates
with their own GitLab Observability API key, which their MCP client sends with
every request. Access is scoped to what that key is allowed to see.

To create an API key:

1. In the top bar, select **Search or go to** and find your group or personal project.
1. In the left sidebar, select **Observe** > **API Keys**.
1. Create a key and copy it.

> [!warning]
> Store your API key securely. Do not commit it to version control. Use your MCP
> client's secret management or environment variable support if available.

## Get your MCP endpoint

1. In the top bar, select **Search or go to** and find your group or personal project.
1. In the left sidebar, select **Observe** > **Setup**.
1. In the **MCP server** section, copy the **MCP endpoint**.

Your MCP endpoint follows this pattern:

```plaintext
https://<namespace_id>.mcp.gitlab-o11y.com/mcp
```

Replace `<namespace_id>` with the ID of the namespace where you enabled
Observability. The namespace ID is your group ID, or your personal namespace ID
if you enabled Observability on a personal project.

## Connect a client

1. Add the MCP server to your client as a new remote HTTP MCP server, using the
   endpoint you copied.
1. When your client prompts for authentication, provide the API key you created.
   Your client sends it as the `SIGNOZ-API-KEY` header.
1. Verify the connection in your client. For example, list the available MCP
   tools, then start asking questions about your observability data.

## Available tools

The MCP server exposes tools for reading and exploring your observability data,
including:

- Metrics: list and query
- Logs: search and aggregate
- Traces: search and inspect individual traces and spans
- Services: list and view top operations
- Alerts: list and inspect alert rules
- Dashboards: list and inspect dashboards and saved views

Your AI assistant chooses the appropriate tools to answer your question and
returns results drawn from your instance's data.

## Related topics

- [Access the Observability API](api_access.md)
- [Send telemetry data to GitLab Observability](send.md)
- [Troubleshooting Observability](troubleshooting.md)

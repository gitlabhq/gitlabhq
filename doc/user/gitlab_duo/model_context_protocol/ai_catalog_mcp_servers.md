---
stage: AI-powered
group: Workflow Catalog
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: Connect custom agents in the AI Catalog to external data sources and third-party services using MCP servers.
title: MCP servers in the AI Catalog
---

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com
- Status: Experiment

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/work_items/590708) in GitLab 18.10 [with a flag](../../../administration/feature_flags/_index.md) named `ai_catalog_mcp_servers`. Disabled by default.

{{< /history >}}

> [!flag]
> The availability of this feature is controlled by a feature flag.
> For more information, see the history.
> This feature is available for testing, but not ready for production use.

Custom agents in the AI Catalog can connect to external data sources and
third-party services (such as Jira or Google Drive) through the
[Model Context Protocol](https://modelcontextprotocol.io/) (MCP).

This feature is an [experiment](../../../policy/development_stages_support.md#experiment).
Share your feedback in [issue 590708](https://gitlab.com/gitlab-org/gitlab/-/work_items/590708).

With MCP servers in the AI Catalog, you can:

- Add MCP servers to your organization's catalog (name, URL, and transport type).
- Associate MCP servers with custom agents.
- View which MCP servers are connected to each agent.
- Authenticate with OAuth-enabled MCP servers.

A dedicated **MCP** tab appears in the AI Catalog navigation alongside **Agents** and **Flows**.
At the group level, MCP servers associated with namespace agents are also available under **Automate** > **MCP**.

## Prerequisites

- Meet the [prerequisites](../../duo_agent_platform/_index.md#prerequisites).
- Be a member of a top-level group that has
  [turned on GitLab Duo experiment and beta features](../turn_on_off.md#on-gitlabcom-2).
- To add or edit MCP servers, you must have the Owner role for the group.
- The MCP server must be a:
  - Vetted or partner MCP server. Arbitrary URLs are not allowed.
  - Remote MCP server.

## Add an MCP server to the AI Catalog

To add an MCP server to the AI Catalog:

1. On the left sidebar, select **Search or go to** and find your group.
1. Select **Build** > **AI Catalog**.
1. Select the **MCP** tab.
1. Select **New MCP server**.
1. Complete the fields:
   - **Name**: A descriptive name for the MCP server (for example, `Jira`).
   - **Description** (optional): A brief description of what the server provides.
   - **URL**: The HTTP endpoint of the MCP server.
   - **Homepage URL** (optional): The homepage or documentation URL for the MCP server.
   - **Transport**: Select **HTTP**. Only HTTP transport is supported.
     SSE and stdio transports are not available.
   - **Authentication type**: Select one of the following:
      - **None**: No authentication required.
      - **OAuth**: Authenticate with OAuth 2.0. If the server supports
        [OAuth 2.0 Dynamic Client Registration](https://tools.ietf.org/html/rfc7591),
        GitLab automatically registers itself as an OAuth client on first connection.
1. Select **Create MCP server**.

The MCP server is now available in your organization's catalog and can be associated with agents.

## Edit an MCP server

To edit an MCP server:

1. On the left sidebar, select **Search or go to** and find your group.
1. Select **Build** > **AI Catalog**.
1. Select the **MCP** tab.
1. Select the MCP server you want to edit.
1. Select **Edit**.
1. Update the fields as needed.
1. Select **Save changes**.

## Associate an MCP server with an agent

To give a custom agent access to an MCP server:

1. On the left sidebar, select **Search or go to** and find your group.
1. Select **Build** > **AI Catalog**.
1. Select the **Agents** tab.
1. Select the agent you want to configure, then select **Edit**.
1. In the **MCP servers** section, select the MCP servers to associate with this agent.
1. Select **Save changes**.

The agent can now use all tools provided by the associated MCP server during execution.

You cannot restrict an agent from using specific MCP server tools.

## View MCP servers connected to an agent

To view which MCP servers are connected to an agent:

1. On the left sidebar, select **Search or go to** and find your group.
1. Select **Build** > **AI Catalog**.
1. Select the **Agents** tab.
1. Select the agent.

The agent detail page lists all connected MCP servers.

## View MCP servers for a namespace

The **Automate** > **MCP** page shows all MCP servers associated with agents enabled in your namespace.
Each server displays the number of agents that use it.

To view MCP servers for a namespace:

1. On the left sidebar, select **Search or go to** and find your group.
1. Select **Automate** > **MCP**.

For OAuth-enabled servers that you have not yet authenticated with, an option to **Connect** is displayed.

## Authenticate with an MCP server

To authenticate with an OAuth-enabled MCP server:

1. On the left sidebar, select **Search or go to** and find your group.
1. Select **Automate** > **MCP**.
1. Find the MCP server and select **Connect**.
1. Review and approve the authorization request on the MCP server's authorization page.
1. GitLab stores the access token securely for future requests.

If the server supports [OAuth 2.0 Dynamic Client Registration](https://tools.ietf.org/html/rfc7591),
GitLab automatically registers itself as an OAuth client on first connection.
You do not need to provide OAuth credentials manually.

## Related topics

- [Model Context Protocol](../_index.md)
- [GitLab MCP clients](mcp_clients.md)
- [GitLab MCP server](mcp_server.md)
- [Get started with the Model Context Protocol](https://modelcontextprotocol.io/introduction)

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
Share your feedback in [issue 593219](https://gitlab.com/gitlab-org/gitlab/-/work_items/593219).

With MCP servers in the AI Catalog, you can:

- Add MCP servers to your organization's catalog (name, URL, and transport type).
- Associate MCP servers with custom agents.
- View which MCP servers are connected to each agent.
- Authenticate with OAuth-enabled MCP servers.

A dedicated **MCP** tab appears in the AI Catalog navigation alongside **Agents** and **Flows**.
MCP servers associated with agents enabled in your namespace are also available under **AI** > **MCP servers**
at both the group and project level.

## Prerequisites

- Meet the [prerequisites for the GitLab Duo Agent Platform](../../duo_agent_platform/_index.md#prerequisites).
- Be a member of a top-level group that has
  [turned on GitLab Duo experiment and beta features](../turn_on_off.md#on-gitlabcom-2).
- To add or edit MCP servers, you must be an instance administrator.
- The MCP server must be a:
  - Vetted or partner MCP server. Arbitrary URLs are not allowed.
  - Remote MCP server.

## Add an MCP server to the AI Catalog

To add an MCP server to the AI Catalog:

1. In the left sidebar, select **Search or go to** and find your group.
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

1. In the left sidebar, select **Search or go to** and find your group.
1. Select **Build** > **AI Catalog**.
1. Select the **MCP** tab.
1. Select the MCP server you want to edit.
1. Select **Edit**.
1. Update the fields as needed.
1. Select **Save changes**.

## Connect an MCP server to a custom agent

To connect an MCP server to a custom agent:

1. In the left sidebar, select **Search or go to** and find your group.
1. Select **Build** > **AI Catalog**.
1. Select the **Agents** tab.
1. Select the agent you want to configure, then select **Edit**.
1. In the **MCP servers** section, select the MCP servers to associate with this agent.
1. Select **Save changes**.

The agent can now use all tools provided by the associated MCP server during execution.

You cannot restrict an agent from using specific MCP server tools.

## View MCP servers connected to a custom agent

To view which MCP servers are connected to a custom agent:

1. In the left sidebar, select **Search or go to** and find your group.
1. Select **Build** > **AI Catalog**.
1. Select the **Agents** tab.
1. Select the agent.

The agent detail page lists all connected MCP servers.

## Disconnect an MCP server from custom agents

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/227157) in GitLab 18.11.

{{< /history >}}

You can disconnect an MCP server from all custom agents that it has a connection
to. You cannot disconnect an MCP server from a specific agent.

After disconnecting, existing custom agent chats can still reference content
already retrieved from the MCP server. However, agents are no longer able to
fetch new content or perform any actions.

1. In the left sidebar, select **Search or go to** and find your group.
1. Select **Build** > **AI Catalog**.
1. Select the **MCP** tab.
1. For the MCP server you want to disconnect, select **Disconnect**.
1. In the confirmation dialog, select **Disconnect**.

## View MCP servers for a namespace

The **AI** > **MCP servers** page shows all MCP servers associated with agents enabled in your namespace.
Each server displays the number of agents that use it, with agent names shown in a tooltip on hover.

This page is available at both the group and project level:

- **Group level** shows MCP servers associated with agents across the group.
- **Project level** shows MCP servers associated with agents configured in the project.

To view MCP servers at the group or project level:

1. In the left sidebar, select **Search or go to** and find your group or project.
1. Select **AI** > **MCP servers**.

For OAuth-enabled servers that you have not yet authenticated with, an option to **Connect** is displayed.

## Authenticate with an MCP server

To authenticate with an OAuth-enabled MCP server:

1. In the left sidebar, select **Search or go to** and find your group or project.
1. Select **AI** > **MCP servers**.
1. Find the MCP server and select **Connect**.
1. Review and approve the authorization request on the MCP server's authorization page.
1. GitLab stores the access token securely for future requests.

If the server supports [OAuth 2.0 Dynamic Client Registration](https://tools.ietf.org/html/rfc7591),
GitLab automatically registers itself as an OAuth client on first connection.
You do not need to provide OAuth credentials manually.

## Available MCP servers

You can add the following MCP servers to the AI Catalog.
For more servers proposed for the catalog, see [issue 591969](https://gitlab.com/gitlab-org/gitlab/-/work_items/591969).

### Linear

The Linear MCP server allows AI agents and workflows to interact with Linear data in real-time,
including finding, creating, and updating issues, projects, and comments.

| Property | Value |
|---|---|
| URL | `https://mcp.linear.app/mcp` |
| Transport | HTTP |
| Authentication | OAuth |

### Atlassian

The Atlassian MCP server allows AI agents and workflows to interact with Jira and Confluence data
in real-time, including searching, creating, and updating issues, pages, and project content.

| Property | Value |
|---|---|
| URL | `https://mcp.atlassian.com/v1/mcp` |
| Transport | HTTP |
| Authentication | OAuth |

Before connecting, configure your Atlassian instance to trust GitLab as an authorized domain:

1. In Atlassian, go to the admin page.
1. Select **Apps** > **AI Settings** > **Rovo MCP Server**.
1. Add `https://gitlab.com/**` to the list of trusted domains.

### Context7

Context7 MCP pulls up-to-date, version-specific documentation and code examples from the
source and adds them to your prompt.

| Property | Value |
|---|---|
| URL | `https://mcp.context7.com/mcp` |
| Transport | HTTP |
| Authentication | None |

## Related topics

- [GitLab MCP server](mcp_server.md)

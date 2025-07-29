---
stage: AI-powered
group: Duo Workflow
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: Describes Model Context Protocol and how to use it
title: Use Model Context Protocol with AI-native features
---

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Status: Experiment

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
- The [software development flow](../../../user/duo_agent_platform/software_development_flow.md)

This means that, in addition to GitLab information, these features
can now use context and information external to GitLab to generate more powerful
answers for customers.

To use a feature with MCP:

- Turn on MCP for your group.
- Specify the MCP servers you want the feature to connect to.

## Prerequisites

Before you can use a GitLab Duo feature with MCP, you must:

- Install [Visual Studio Code](https://code.visualstudio.com/download) (VS Code).
- Set up the [GitLab Workflow extension for VS Code](https://marketplace.visualstudio.com/items?itemName=GitLab.gitlab-workflow#setup). MCP requires version 6.28.2 and later.
- Meet the feature prerequisites as required:

  - [Agentic Chat prerequisites](../../../user/gitlab_duo_chat/agentic_chat.md#use-agentic-chat-in-vs-code).
  - [Software development flow prerequisites](../../../user/duo_agent_platform/software_development_flow.md#prerequisites).

## Turn on MCP for your group

To turn MCP on or off for your group:

1. On the left sidebar, select **Search or go to** and find your group.
1. Select **Settings > GitLab Duo**.
1. Select **Change configuration**.
1. Under **Model Context Protocol**, select or clear the
   **Turn on Model Context Protocol (MCP) support** checkbox.
1. Select **Save changes**.

## Specify the MCP servers

To specify the MCP servers you want the GitLab Duo feature to connect to:

1. In VS Code, create a MCP server configuration file:

   - If you are not on Windows, create the file in `~/.gitlab/duo/mcp.json`.
   - If you are on Windows, create the file in `C:\Users\<username>\AppData\Roaming\GitLab\duo\mcp.json`.

1. Populate this file with the MCP servers you want the feature to connect to.

1. Save the file.

### Example MCP server configuration files

Use the following code examples to help you create your MCP server configuration file.

For more information and examples, see the [MCP example servers documentation](https://modelcontextprotocol.io/examples). You can also find other example servers at [Smithery.ai](https://smithery.ai/) and [Awesome MCP Servers](https://mcpservers.org/).

#### Local

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

#### Remote

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
     dialog appears. You can enter a rejection reason into the text box and select
     **Submit Rejection**.

## Feedback

Because this is an experimental feature, your feedback is valuable in helping us
to improve it. Share your experiences, suggestions, or issues in
[issue 552164](https://gitlab.com/gitlab-org/gitlab/-/issues/552164).

## Related topics

- [Get started with the Model Context Protocol](https://modelcontextprotocol.io/introduction)
- [Demo - Agentic Chat MCP Tool Call Approval](https://www.youtube.com/watch?v=_cHoTmG8Yj8)

## Troubleshooting

For troubleshooting information, see [troubleshooting the GitLab Workflow extension for VS Code](../../../editor_extensions/visual_studio_code/troubleshooting.md).

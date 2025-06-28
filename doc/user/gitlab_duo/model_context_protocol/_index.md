---
stage: AI-powered
group: Duo Workflow
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: Describes Model Context Protocol and how to use it
title: Use Model Context Protocol with AI-native features
---

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com
- Status: Experiment

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/519938) in GitLab 18.1 [with a flag](../../../administration/feature_flags/_index.md) named `duo_workflow_mcp_support`. Disabled by default.
- [Enabled on GitLab.com](https://gitlab.com/gitlab-org/gitlab/-/issues/545956) in GitLab 18.2. Feature flag `duo_workflow_mcp_support` removed.

{{< /history >}}

The Model Context Protocol (MCP) provides a standardized way for AI-native features
to securely connect to different external data sources and tools.

The following GitLab Duo AI-native features can act as MCP clients, and connect to and run
external tools from MCP servers:

- [GitLab Duo Agentic Chat](../../gitlab_duo_chat/agentic_chat.md)

This means that, in addition to GitLab information, these AI-native features
can now use context and information external to GitLab to generate more powerful
answers for customers.

To use a GitLab Duo AI-native feature with MCP:

- Turn on MCP for your group.
- Specify the MCP servers you want the feature to connect to.

## Prerequisites

Before you can use an AI-native feature with MCP, you must:

- [Install Visual Studio Code](https://code.visualstudio.com/download) (VS Code).
- [Set up the GitLab Workflow extension for VS Code](https://marketplace.visualstudio.com/items?itemName=GitLab.gitlab-workflow#setup).
- Meet the following AI-native feature prerequisites:
  - [Agentic Chat prerequisites](../../gitlab_duo_chat/agentic_chat.md#use-agentic-chat-in-vs-code).

## Turn on MCP for your group

To turn MCP on or off for your group:

1. On the left sidebar, select **Search or go to** and find your group.
1. Select **Settings > GitLab Duo**.
1. Select **Change configuration**.
1. Under **Model Context Protocol**, select or clear the
   **Turn on Model Context Protocol (MCP) support** checkbox.
1. Select **Save changes**.

## Specify the MCP servers

To specify the MCP servers you want the AI-native feature to connect to:

1. In VS Code, create an `mcp.json` file in `~/gitlab/duo/`.
1. Populate this file with the MCP servers you want the feature to connect to.

   For more information and examples, see the [MCP example servers documentation](https://modelcontextprotocol.io/examples). You can also find other example servers at [Smithery.ai](https://smithery.ai/)
   and [Awesome MCP Servers](https://mcpservers.org/).

1. Save the file.

## Use AI-native features with MCP

When an AI-native feature wants to call an external tool to answer
the question you have asked, you must review and approve or deny the tool before
the feature can use that tool:

1. Open VS Code.
1. On the left sidebar, select the feature.
1. In the text box, enter a question or specify a code task.
1. Submit the question or code task.
1. The **Tool Approval Required** dialog appears.

   Review the tool and select **Approve** or **Deny**.

   - If you approve the tool, the feature connects to the tool and
   generates an answer.

   - If you deny the tool, the **Provide Rejection Reason** dialog appears.
     Optional: Enter a rejection reason into the text box and select
     **Submit Rejection**.

## Related topics

- [Get started with the Model Context Protocol](https://modelcontextprotocol.io/introduction)
- [Demo - Agentic Chat MCP Tool Call Approval](https://www.youtube.com/watch?v=_cHoTmG8Yj8)

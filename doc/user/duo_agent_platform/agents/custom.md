---
stage: AI-powered
group: Workflow Catalog
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Custom agents
---

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed

{{< /details >}}

{{< collapsible title="Model information" >}}

- Available on [GitLab Duo with self-hosted models](../../../administration/gitlab_duo_self_hosted/_index.md)

{{< /collapsible >}}

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/549914) in GitLab 18.5 [with a flag](../../../administration/feature_flags/_index.md) named `global_ai_catalog`. Enabled on GitLab.com.
- Enabling in groups [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/580307) in GitLab 18.7 [with a flag](../../../administration/feature_flags/_index.md) named `ai_catalog_agents`. Enabled on GitLab.com.
- [Changed](https://gitlab.com/gitlab-org/gitlab/-/issues/568176) to beta in GitLab 18.7.
- [Generally available](https://gitlab.com/gitlab-org/gitlab/-/work_items/585273) in GitLab 18.8.
- Feature flag `ai_catalog_agents` [removed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/217802) in GitLab 18.9.

{{< /history >}}

> [!flag]
> The availability of this feature is controlled by a feature flag.
> For more information, see the history.

Agents use AI to perform tasks and answer complex questions. Create
custom agents to accomplish specific tasks, like creating merge
requests or reviewing code. Or, use the AI Catalog to discover agents
created by GitLab.

When you're ready to interact with an agent, enable it and start using it
with GitLab Duo Chat in the GitLab UI, VS Code, and JetBrains IDEs.

## Prerequisites

- Meet the [prerequisites for the GitLab Duo Agent Platform](../_index.md#prerequisites).

## Agent visibility

When you create a custom agent, you select a project to manage it and choose whether the agent is public or private.

Public agents:

- Can be viewed by anyone and can be enabled in any project that meets the prerequisites.

Private agents:

- Can be viewed only by members of the managing project who have the Developer, Maintainer, or Owner role.
- Cannot be enabled in projects other than the managing project.

You cannot make a public agent private if the agent is currently enabled.

## View the agents for your project

Prerequisites:

- You must have the Developer, Maintainer, or Owner role for the project.

To view a list of agents associated with your project:

1. On the top bar, select **Search or go to** and find your project.
1. Select **Automate** > **Agents**.
   - To view agents enabled in the project, select the **Enabled** tab.
   - To view agents managed by the project, select the **Managed** tab.

Select an agent to view its details.

## Create an agent

You can create an agent from a project, or by using the AI Catalog.

Prerequisites:

- You must have the Maintainer or Owner role for the project.

{{< tabs >}}

{{< tab title="From a project" >}}

To create an agent:

1. On the top bar, select **Search or go to** and find your project.
1. Select **Automate** > **Agents**.
1. Select **New agent**.
1. Under **Basic information**:
   1. In **Display name**, enter a name for the agent.
   1. In **Description**, enter a description for the agent.
1. Under **Visibility & access**, for **Visibility**, select **Private** or **Public**.
1. Under **Prompts**, in **System prompt**, enter a prompt to define
   the agent's personality, expertise, and behavior.
1. Optional. Under **Available tools**, from the **Tools** dropdown list,
   select which tools the agent can access.
   For example, for the agent to create issues automatically, select **Create issue**.

   For more information, see the list of [agent tools](tools.md).
1. Select **Create agent**.

{{< /tab >}}

{{< tab title="From the AI Catalog" >}}

To create an agent:

1. On the top bar, select **Search or go to** > **Explore**.
1. Select **AI Catalog**, then select the **Agents** tab.
1. Select **New agent**.
1. Under **Basic information**:
   1. In **Display name**, enter a name for the agent.
   1. In **Description**, enter a description for the agent.
1. Under **Visibility & access**:
   1. From the **Managed by** dropdown list, select a project for the agent.
   1. For **Visibility**, select **Private** or **Public**.
1. Under **Prompts**, in **System prompt**, enter a prompt to define
   the agent's personality, expertise, and behavior.
1. Optional. Under **Available tools**, from the **Tools** dropdown list,
   select which tools the agent can access.
   For example, for the agent to create issues automatically, select **Create issue**.

   For a list of available tools, see the [built-in tool definitions](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/lib/ai/catalog/built_in_tool_definitions.rb).
1. Select **Create agent**.

{{< /tab >}}

{{< /tabs >}}

The agent appears in the AI Catalog. To use the agent with Chat, you must enable it.

## Enable an agent

Enable an agent to use it with Chat.

Prerequisites:

- You must have the Maintainer or Owner role for the top-level group.
- You must have the Maintainer or Owner role for the project.

{{< tabs >}}

{{< tab title="From the managing project" >}}

To enable an agent:

1. On the top bar, select **Search or go to** and find your project.
1. Select **Automate** > **Agents**.
1. Select the **Managed** tab, then select the agent you want to enable.
1. In the upper-right corner, select **Enable**.
1. Under **Group**, select the group you want to enable the agent in.
1. Under **Project**, select the project you want to enable the agent in.
1. Select **Enable**.

{{< /tab >}}

{{< tab title="From the AI Catalog" >}}

To enable an agent:

1. On the top bar, select **Search or go to** > **Explore**.
1. Select **AI Catalog**, then select the **Agents** tab.
1. Select the agent you want to enable.
1. In the upper-right corner, select **Enable**.
1. Under **Group**, select the group you want to enable the agent in.
1. Under **Project**, select the project you want to enable the agent in.
1. Select **Enable**.

{{< /tab >}}

{{< /tabs >}}

The agent appears in the group and project **Automate** > **Agents** pages.

In the project, you can start a new chat with the agent.
For more information, see [select an agent](../../gitlab_duo_chat/agentic_chat.md#select-an-agent).

### Enable in a project

If an agent is already enabled in a top-level group, you can enable it in the group's projects.

Prerequisites:

- You must have the Maintainer or Owner role for the project.
- The agent must be enabled in a top-level group.

To enable an agent in a project:

1. On the top bar, select **Search or go to** and find your project.
1. Select **Automate** > **Agents**.
1. In the upper-right corner, select **Enable agent from group**.
1. From the dropdown list, select the agent you want to enable.
1. Select **Enable**.

The agent appears in the project's **Automate** > **Agents** page.

In the project, you can start a new chat with the agent.

## Use an agent

You can use a custom agent in the GitLab UI, VS Code, and JetBrains IDEs.

### In the GitLab UI

Prerequisites:

- Enable the agent in a top-level group and the project you want to use it in.

To use a custom agent in the GitLab UI:

1. On the top bar, select **Search or go to** and find your project or group.
1. Open an issue, epic, or merge request.
1. On the GitLab Duo sidebar, select either **New GitLab Duo Chat**
   ({{< icon name="pencil-square" >}}) or **Current GitLab Duo Chat**
   ({{< icon name="duo-chat" >}}).

   A Chat conversation opens in the GitLab Duo sidebar on the right side of your screen.

1. From the **New chat** ({{< icon name="duo-chat-new" >}}) dropdown list, select the custom agent.
1. Enter your question or request.

### In VS Code

Prerequisites:

- Enable the agent in a top-level group and the project you want to use it in.
- Install and configure [GitLab for VS Code](../../../editor_extensions/visual_studio_code/setup.md)
  version 6.47.0 or later.
- Set a [default GitLab Duo namespace](../../profile/preferences.md#set-a-default-gitlab-duo-namespace).

To use a custom agent in VS Code:

1. In VS Code, on the left sidebar, select **GitLab Duo Agent Platform** ({{< icon name="duo-agentic-chat" >}}).
1. Select the **Chat** tab.
1. From the **New chat** ({{< icon name="duo-chat-new" >}}) dropdown list, select the custom agent.
1. Enter your question or request.

### In JetBrains IDEs

Prerequisites:

- Enable the agent in a top-level group and the project you want to use it in.
- Install and configure [GitLab plugin for JetBrains](../../../editor_extensions/jetbrains_ide/setup.md)
  version 3.19.0 or later.
- Set a [default GitLab Duo namespace](../../profile/preferences.md#set-a-default-gitlab-duo-namespace).

First, enable the GitLab Duo Agent Platform:

1. In your JetBrains IDE, go to **Settings** > **Tools** > **GitLab Duo**.
1. Under **GitLab Duo Agent Platform**, select the **Enable GitLab Duo Agent Platform** checkbox.
1. Restart your IDE if prompted.

Then, to use a custom agent:

1. In your JetBrains IDE, on the right tool window bar, select **GitLab Duo Agent Platform** ({{< icon name="duo-agentic-chat" >}}).
1. Select the **Chat** tab.
1. From the **New chat** ({{< icon name="duo-chat-new" >}}) dropdown list, select the custom agent.
1. Enter your question or request.

## Disable an agent

Prerequisites:

- For groups, you must have the Owner role.
- For projects, you must have the Maintainer or Owner role.

To disable an agent:

1. On the top bar, select **Search or go to** and find your group or project.
1. Select **Automate** > **Agents**.
1. Find the agent you want to remove and select **Actions** ({{< icon name="ellipsis_v" >}}) > **Disable**.
1. On the confirmation dialog, select **Disable**.

The agent no longer appears in the project, and is not available in Chat.

## Duplicate an agent

To make changes to an agent without overwriting the original, create a copy of an existing agent.

Prerequisites:

- You must have the Maintainer or Owner role for the project.

To duplicate an agent:

1. On the top bar, select **Search or go to** > **Explore**.
1. Select **AI Catalog**, then select the **Agents** tab.
1. Select the agent you want to duplicate.
1. In the upper-right corner, select **Actions** ({{< icon name="ellipsis_v" >}}) > **Duplicate**.
1. Optional. Edit any fields you want to change.
1. Select **Create agent**.

## Edit an agent

Edit an agent to change its configuration.

Prerequisites:

- You must be a member of the managing project and have the Maintainer or Owner role.

1. In the top bar, select **Search or go to** and find your group or project.
1. Select **Automate** > **Agents**.
1. Select the agent you want to edit.
1. In the upper-right corner, select **Edit**.
1. Edit any fields you want to change, then select **Save changes**.

## Hide an agent

Hide an agent to remove it from the AI Catalog.

After you hide an agent, users can't enable it. However, they can still interact with the agent in the groups and projects it is already enabled in.

Prerequisites:

- You must be a member of the managing project and have the Maintainer or Owner role.

To hide an agent:

1. In the top bar, select **Search or go to** and find your group or project.
1. Select **Automate** > **Agents**.
1. Find the agent you want to hide and select **Actions** ({{< icon name="ellipsis_v" >}}) > **Hide**.
1. In the confirmation dialog, select **Confirm**.

## Delete an agent

Delete an agent to permanently remove it from the instance.

Prerequisites:

- You must be an administrator.

1. In the top bar, select **Search or go to** and find your group or project.
1. Select **Automate** > **Agents**.
1. Find the agent you want to delete and select **Actions** ({{< icon name="ellipsis_v" >}}) > **Delete**.
1. In the confirmation dialog, select **Delete**.

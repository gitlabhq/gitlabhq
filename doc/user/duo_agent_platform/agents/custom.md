---
stage: AI-powered
group: Workflow Catalog
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Custom agents
---

{{< details >}}

- Tier: Premium, Ultimate
- Add-on: GitLab Duo Core, Pro, or Enterprise
- Offering: GitLab.com, GitLab Self-Managed
- Status: Experiment

{{< /details >}}

{{< collapsible title="Model information" >}}

- Not available on GitLab Duo with self-hosted models

{{< /collapsible >}}

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/549914) in GitLab 18.5 [with a flag](../../../administration/feature_flags/_index.md) named `global_ai_catalog`. Enabled on GitLab.com.
- Enabling in groups [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/580307) in GitLab 18.7 [with a flag](../../../administration/feature_flags/_index.md) named `ai_catalog_agents`. Enabled on GitLab.com.

{{< /history >}}

{{< alert type="flag" >}}

The availability of this feature is controlled by a feature flag.
For more information, see the history.

{{< /alert >}}

Agents use AI to perform tasks and answer complex questions. Create
custom agents to accomplish specific tasks, like creating merge
requests or reviewing code. Or, use the AI Catalog to discover agents
created by GitLab.

When you're ready to interact with an agent, you can enable it to
start using it with GitLab Duo Chat.

## Agent visibility

When you create a custom agent, you select a project to manage it and choose whether the agent is public or private.

Public agents:

- Can be viewed by anyone and can be enabled in any project that meets the prerequisites.

Private agents:

- Can be viewed only by members of the managing project who have at least the Developer role.
- Cannot be enabled in projects other than the managing project.

You cannot make a private agent public if the agent is currently enabled.

## View the agents for your project

Prerequisites:

- You must have at least the Developer role for the project.

To view a list of agents associated with your project:

1. On the top bar, select **Search or go to** and find your project.
1. Select **Automate** > **Agents**.
   - To view agents enabled in the project, select the **Enabled** tab.
   - To view agents managed by the project, select the **Managed** tab.

Select an agent to view its details.

## Create an agent

You can create an agent from a project, or by using the AI Catalog.

Prerequisites:

- You must have at least the Maintainer role for the project.

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

   For a list of available tools, see the [built-in tool definitions](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/lib/ai/catalog/built_in_tool_definitions.rb).
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

The agent appears in the AI Catalog. To use the agent with Chat, enable it in a project.

## Enable an agent

Enable an agent to use it with Chat. To enable an agent, you must:

1. Enable it in a top-level group.
1. Enable it in the project you want to use it in.

### Enable in a top-level group

Prerequisites:

- You must have the Owner role for the group.

To enable an agent in a top-level group:

1. On the top bar, select **Search or go to** > **Explore**.
1. Select **AI Catalog**, then select the **Agents** tab.
1. Select the agent you want to enable.
1. In the upper-right corner, select **Enable in group**.
1. From the dropdown list, select the group you want to enable the agent in.
1. Select **Enable**.

The agent appears in the group's **Automate** > **Agents** page.

### Enable in a project

Prerequisites:

- You must have at least the Maintainer role for the project.
- The agent must be enabled in a top-level group.

To enable an agent in a project:

1. On the top bar, select **Search or go to** and find your project.
1. Select **Automate** > **Agents**.
1. In the upper-right corner, select **Enable agent from group**.
1. From the dropdown list, select the agent you want to enable.
1. Select **Enable**.

The agent appears on the project's **Automate** > **Agents** page.
In the project, you can start a new chat with the agent.
For more information, see [select an agent](../../gitlab_duo_chat/agentic_chat.md#select-an-agent).

### Disable an agent

Prerequisites:

- For groups, you must have the Owner role.
- For projects, you must have at least the Maintainer role.

To disable an agent:

1. On the top bar, select **Search or go to** and find your group or project.
1. Select **Automate** > **Agents**.
1. Find the agent you want to remove and select **Actions** ({{< icon name="ellipsis_v" >}}) > **Disable**.
1. On the confirmation dialog, select **Disable**.

The agent no longer appears in the project, and is not available in Chat.

## Duplicate an agent

To make changes to an agent without overwriting the original, create a copy of an existing agent.

Prerequisites:

- You must have at least the Maintainer role for the project.

To duplicate an agent:

1. On the top bar, select **Search or go to** > **Explore**.
1. Select **AI Catalog**, then select the **Agents** tab.
1. Select the agent you want to duplicate.
1. In the upper-right corner, select **Actions** ({{< icon name="ellipsis_v" >}}) > **Duplicate**.
1. Optional. Edit any fields you want to change.
1. Select **Create agent**.

## Manage agents

Edit an agent to change its configuration, or delete it to remove it from the AI Catalog.

Prerequisites:

- You must be a member of the managing project and have at least the Maintainer role.

To manage an agent:

1. On the top bar, select **Search or go to** > **Explore**.
1. Select **AI Catalog**, then select the **Agents** tab.
1. Select the agent you want to manage.
   - To edit an agent:
     1. In the upper-right corner, select **Edit**.
     1. Edit any fields you want to change, then select **Save changes**.
   - To delete an agent:
     1. In the upper-right corner, select **Actions** ({{< icon name="ellipsis_v" >}}) > **Delete**.
     1. On the confirmation dialog, select **Delete**.

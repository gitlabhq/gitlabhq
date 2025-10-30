---
stage: AI-powered
group: Workflow Catalog
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Agents
---

{{< details >}}

- Tier: Premium, Ultimate
- Add-on: GitLab Duo Core, Pro, or Enterprise
- Offering: GitLab.com
- Status: Experiment

{{< /details >}}

{{< collapsible title="Model information" >}}

- LLM: Anthropic [Claude Sonnet 4](https://www.anthropic.com/claude/sonnet)

{{< /collapsible >}}

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/549914) in GitLab 18.5 [with a flag](../../../administration/feature_flags/_index.md) named `global_ai_catalog`. Enabled on GitLab.com. This feature is an [experiment](../../../policy/development_stages_support.md).

{{< /history >}}

{{< alert type="flag" >}}

The availability of this feature is controlled by a feature flag.
For more information, see the history.

{{< /alert >}}

Agents use AI to perform tasks and answer complex questions.
Create custom agents to accomplish specific tasks, like creating
merge requests or reviewing code. Or, use the AI Catalog to discover
agents created by GitLab.

When you're ready to interact with an agent, you can enable it or execute a test run.

## Prerequisites

To use agents, you must meet the [prerequisites](../_index.md#prerequisites).

There are additional requirements depending on the agent's visibility.

### Agent visibility

When you create an agent, you associate it with a source project and choose whether it is public or private.

- A public agent can be viewed by anyone and can be enabled in any project that meets the prerequisites.
- A private agent can be viewed only by members of the source project who have at least the Developer role.
  Private agents cannot be enabled in projects other than the source project.
  You cannot make a private agent public if the agent is currently enabled.

## Create an agent

Prerequisites:

- You must have at least the Maintainer role for the project.

To create an agent:

1. On the left sidebar, select **Search or go to** > **Explore**.
1. Select **AI Catalog**.
1. Select the **Agents** tab, then select **New agent**.
1. Under **Basic information**:
   1. In **Display name**, enter a name for the agent.
   1. In **Description**, enter a description for the agent.
1. Under **Visibility & access**:
   1. For **Visibility**, select **Private** or **Public**.
   1. From the **Source project** dropdown list, select a project for the agent.
1. Under **Prompts**, in **System prompt**, enter a prompt to define
   the agent's personality, expertise, and behavior.
1. Optional. Under **Available tools**, from the **Tools** dropdown list,
   select which tools the agent can access. For a list of available tools, see the [built-in tool definitions](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/lib/ai/catalog/built_in_tool_definitions.rb).
   For example, for the agent to create issues automatically, select **Create issue**.
1. Select **Create agent**.

The agent is enabled in the source project, and appears in the AI Catalog.

## Enable an agent

Enable an agent in a project to use it with Chat.
By default, an agent is enabled in its source project.

Prerequisites:

- You must have at least the Maintainer role for the project.

1. On the left sidebar, select **Search or go to** > **Explore**.
1. Select **AI Catalog** and find the agent you want to enable.
1. Next to the agent name, select **Actions** ({{< icon name="ellipsis_v" >}}) > **Enable in project**.
1. From the **Project** dropdown list, select your project.
1. Select **Enable**.

The agent appears on the project's **Agents** page.

## Run an agent

Execute a test run to start a session with the agent.

Prerequisites:

- You must be a member of the source project and have at least the Maintainer role.

To run an agent:

1. On the left sidebar, select **Search or go to** > **Explore**.
1. Select **AI Catalog**.
1. Select your agent, then select **Test**.
1. On the dialog, enter your instructions, then select **Run**.

To monitor progress, select **Automate** > **Sessions**.

## Duplicate an agent

Create a copy of an existing agent in a different source project.
Do this if you want to use an agent someone else created, or make changes to an agent without overwriting the original.

Prerequisites:

- You must have at least the Maintainer role for the project.

To duplicate an agent:

1. On the left sidebar, select **Search or go to** > **Explore**.
1. Select **AI Catalog** and find the agent you want to duplicate.
1. Next to the agent name, select **Actions** ({{< icon name="ellipsis_v" >}}) > **Duplicate**.
1. Optional. Edit any fields you want to change.
1. Select **Create agent**.

## Manage agents

Edit an agent to change its configuration, or delete it to remove it from the AI Catalog.

Prerequisites:

- You must be a member of the source project and have at least the Maintainer role.

1. On the left sidebar, select **Search or go to** > **Explore**.
1. Select **AI Catalog** and find the agent you want to manage.
1. Next to the agent name, select **Actions** ({{< icon name="ellipsis_v" >}}).
   - To edit an agent:
     1. Select **Edit**.
     1. Edit any fields you want to change, then select **Save changes**.
   - To delete an agent:
     1. Select **Delete**.
     1. On the confirmation dialog, select **Delete**.

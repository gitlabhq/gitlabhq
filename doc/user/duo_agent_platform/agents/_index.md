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

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/549914) in GitLab 18.5 [with a flag](../../../administration/feature_flags/_index.md) named `global_ai_catalog`. Disabled by default. This feature is an [experiment](../../../policy/development_stages_support.md).
- Agent tools [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/569043) in GitLab 18.5 [with a flag](../../../administration/feature_flags/_index.md) named `ai_catalog_agent_tools`. Disabled by default.
- Feature flag `ai_catalog_agent_tools` removed in GitLab 18.5.

{{< /history >}}

{{< alert type="flag" >}}

The availability of this feature is controlled by a feature flag.
For more information, see the history.

{{< /alert >}}

Agents use AI to perform tasks and answer complex questions.
Create custom agents to accomplish specific tasks, like creating
merge requests or reviewing code. Or, use the AI Catalog to discover
agents created by GitLab.

When you're ready to interact with an agent, you can add it to a project or execute a test run.

## Prerequisites

To use agents, you must meet the [prerequisites](../_index.md#prerequisites).

There are additional requirements depending on the agent's visibility.

### Agent visibility

When you create an agent, you associate it with a project and choose whether it is public or private.

- A public agent can be viewed by anyone and can be added to any project that meets the prerequisites.
- A private agent can be viewed only by members of the associated project who have at least the Developer role.
  Private agents cannot be added to projects other than the associated project.

## Create an agent

Prerequisites:

- You must have at least the Maintainer role for the project.

To create an agent:

1. On the left sidebar, select **Search or go to** > **Explore**.
1. Select **AI Catalog**.
1. Select **New agent**.
1. Complete the fields:
   1. **Project**: From the dropdown list, select a project. This is the agent's associated project.
   1. **Name**: Enter the name of your agent.
   1. **Description**: Enter a description of the agent.
   1. **Tools**: Optional. Select which built-in tools the agent can use.
      For example, select **Create issue** if you want the agent to be able to create issues automatically.
   1. **System prompt**: Enter guidelines to define the agent's personality or shape how it behaves.
   1. **Visibility level**: Choose whether the agent is public or private.
1. Select **Create agent**.

The agent is added to the AI Catalog.

## Add an agent to a project

Add an agent to a project to use it with Chat.

Prerequisites:

- You must have at least the Maintainer role for the project.

1. On the left sidebar, select **Search or go to** > **Explore**.
1. Select **AI Catalog** and find the agent you want to add.
1. Next to the agent name, select **Actions** ({{< icon name="ellipsis_v" >}}) > **Add to project**.

The agent appears on the project's **Agents** page.

## Run an agent

Execute a test run to start a session with the agent.

Prerequisites:

- You must be a member of the associated project and have at least the Maintainer role.

To run an agent:

1. On the left sidebar, select **Search or go to** > **Explore**.
1. Select **AI Catalog**, find and click on the agent you want to run.
1. In the top right, click on `Test` button which opens a modal.
1. Enter instructions, then select **Run**.

The session starts on the associated project's **Agent sessions** page.

## Duplicate an agent

Create a copy of an existing agent and associate it with a different project.
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

- You must be a member of the associated project and have at least the Maintainer role.

1. On the left sidebar, select **Search or go to** > **Explore**.
1. Select **AI Catalog** and find the agent you want to manage.
1. Next to the agent name, select **Actions** ({{< icon name="ellipsis_v" >}}).
   - To edit an agent:
     1. Select **Edit**.
     1. Edit any fields you want to change, then select **Save changes**.
   - To delete an agent:
     1. Select **Delete**.
     1. On the confirmation dialog, select **Delete**.

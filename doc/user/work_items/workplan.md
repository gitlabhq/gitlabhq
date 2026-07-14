---
stage: Plan
group: Knowledge
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "Capture the intent, approach, and steps for a unit of work in a structured workplan that GitLab Duo agents can run."
title: Workplan
---

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Status: Experiment

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/240718) in GitLab 19.0 [with a feature flag](../../administration/feature_flags/_index.md) named `workplan`. Disabled by default.

{{< /history >}}

> [!flag]
> The availability of this feature is controlled by a feature flag.
> For more information, see the history.
> This feature is available for testing, but not ready for production use.

A workplan is a structured Markdown document attached to a work item. It captures the intent,
approach, and steps for a unit of work.

A workplan provides GitLab Duo agents with an agreed specification and a human-reviewable artifact on the
work item. With this context, an agent has more to work from than a short prompt, so it can run the
work more accurately.

You create a workplan with GitLab Duo or write one manually. GitLab Duo drafts the workplan from the
work item context, and you refine it. Agents then use the workplan as the primary specification for
the work.

The workplan is part of the [GitLab Duo Agent Platform](../duo_agent_platform/_index.md) and the
specification-driven development workflow.

The **Workplan** widget appears on the work item and shows the workplan status:

- **Not yet created**: The work item has no workplan, and you can create one.
- **No workplan**: The work item has no workplan, and you do not have permission to create one.
- **Ready to view**: The work item has a workplan.

## When to use a workplan

Use a workplan when you plan to give work to an agent, either by selecting **Implement**
or by providing the plan to a coding agent yourself. A workplan adds the most value when an agent runs
the work.

You do not need a workplan for small or well-understood changes, where planning adds more effort than it saves.

## Create a workplan

Create a workplan to describe how to complete a unit of work.

Prerequisites:

- Permission to edit the work item.

You can generate a workplan with GitLab Duo or write one manually.

### Generate a workplan with GitLab Duo

Prerequisites:

- [GitLab Duo Chat](../gitlab_duo_chat/agentic_chat.md) turned on.

To generate a workplan with GitLab Duo:

1. On the work item, in the **Workplan** widget, select **Generate**.
1. In GitLab Duo Chat, answer the [Planner Agent](../duo_agent_platform/agents/foundational_agents/planner.md)
   questions until the agent has enough context.
1. Review the proposed plan and approve it.

After you approve the plan, GitLab Duo writes it to the **Workplan** widget.

### Create a workplan manually

To create a workplan manually:

1. On the work item, in the **Workplan** widget, select **More options** > **Create manually**.
1. Optional. From the template dropdown list, select a workplan template.
1. Enter the workplan content. To switch between editors, select **Switch to rich text editing**
   or **Switch to plain text editing**.
1. Select **Save changes**.

Workplan templates are [description templates](../project/description_templates.md) with filenames
that end in `.plan`.

## View a workplan

To view a workplan:

- On the work item, in the **Workplan** widget, select **View**.

The workplan opens in a panel and shows the rendered content.

## Edit a workplan

Prerequisites:

- Permission to edit the work item.

To edit a workplan:

1. On the work item, in the **Workplan** widget, select **View**.
1. In the panel, select **Edit**.
1. Make your changes.
1. Select **Save changes**.

To discard your changes, select **Cancel**.

## Regenerate a workplan

Regenerate a workplan to replace its content with a new version from GitLab Duo.

Prerequisites:

- Permission to edit the work item.

To regenerate a workplan:

1. On the work item, in the **Workplan** widget, select **View**.
1. In the panel, select **More actions** ({{< icon name="ellipsis_v" >}}) > **Regenerate workplan**.
1. In GitLab Duo Chat, answer the Planner Agent questions until the agent has enough context.

GitLab Duo replaces the existing workplan with the new version.

## Delete a workplan

Prerequisites:

- Permission to edit the work item.

To delete a workplan:

1. On the work item, in the **Workplan** widget, select **View**.
1. In the panel, select **More actions** ({{< icon name="ellipsis_v" >}}) > **Delete workplan**.
1. In the confirmation dialog, select **Delete**.

This action cannot be undone.

## Implement a workplan with GitLab Duo

When a workplan exists, GitLab Duo can implement it in a merge request. GitLab Duo treats
the workplan as the primary specification and uses the work item description and comments only for
additional context.

Prerequisites:

- GitLab Duo Agent Platform remote flows turned on.

To implement a workplan with GitLab Duo, use one of the following methods:

- On the work item, in the **Workplan** widget, select **Implement**.
- Open the workplan, then implement it from the panel:
  1. On the work item, in the **Workplan** widget, select **View**.
  1. In the panel, select **Implement**.

## Related topics

- [GitLab Duo Agent Platform](../duo_agent_platform/_index.md)
- [Planner Agent](../duo_agent_platform/agents/foundational_agents/planner.md)
- [Description templates](../project/description_templates.md)
- [Work items](_index.md)

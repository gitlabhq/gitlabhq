---
stage: Plan
group: Planner Intelligence
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
- Workplan widget [changed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/250010) in GitLab 19.4.

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

You can add a workplan to issues and tasks.

After you turn on planning for a work item, the **Workplan**
widget appears and shows the workplan status:

- **Not yet created**: The work item has no workplan, and you can create one.
- **No workplan**: The work item has no workplan, and you do not have permission to create one.
- **Ready to view**: The work item has a workplan.

## Benefits

A workplan separates intent from implementation:

- The work item description captures intent, or what you want and why.
  People read the description to understand the goal.
- The workplan captures implementation, or how to do the work.
  Agents follow the workplan to carry out the work.

This separation gives you three benefits:

- Intent protection: An agent iterates on the workplan in a field separate from the work item
  description, so your intent stays intact even as the plan changes across several runs.
- Plan review: An agent pauses after producing a workplan, so you can review, refine, and approve
  the plan before any work starts.
- Agent focus: Because the workplan is a dedicated field, an agent asked to plan work puts that
  context there instead of rewriting the description or other parts of the work item.

## When to use a workplan

Use a workplan when you plan to give work to an agent, either by selecting **Implement**
or by providing the plan to a coding agent yourself. A workplan adds the most value when an agent runs
the work.

You do not need a workplan for small or well-understood changes, where planning adds more effort than it saves.

## Turn on planning for a work item

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/250010) in GitLab 19.4.

{{< /history >}}

By default, the **Workplan** widget and the confidence score are hidden on a work item.
To show them, turn on planning for that work item.

Prerequisites:

- The work item must be an issue or a task.
- Permission to edit the work item.

To turn on planning:

- On the work item, in the upper-right corner, select **Plan**.

The **Workplan** widget appears on the work item, and the **Plan** button no longer appears.
After you turn on planning for a work item, you cannot turn it off.

## Create a workplan

Create a workplan to describe how to complete a unit of work.

Prerequisites:

- Planning turned on for the work item.
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

## Confidence score

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/248374) in GitLab 19.3 [with a feature flag](../../administration/feature_flags/_index.md) named `workplan_score`. Disabled by default.

{{< /history >}}

> [!flag]
> The availability of this feature is controlled by a feature flag.
> For more information, see the history.
> This feature is available for testing, but not ready for production use.

The confidence score shows how ready a work item is for an agent to run.
GitLab Duo scores the work item on how complete, clear, and well scoped it is, then
maps the score to a confidence level.

Prerequisites:

- Planning turned on for the work item.

In the **Workplan** widget on the work item, the confidence level appears as
**Low**, **Medium**, or **High**.
The score appears whether or not the work item has a workplan.

To raise the score, add more detail to the work item description and to the workplan
steps, such as requirements, acceptance criteria, and constraints.

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

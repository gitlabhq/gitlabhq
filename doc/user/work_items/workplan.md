---
stage: Plan
group: Planner Intelligence
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "Capture the intent, approach, and steps for a unit of work in a structured workplan that GitLab Duo flows can run."
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
- **View** and **Implement** workplan actions in the GitLab Duo Agentic Chat empty state [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/252727) in GitLab 19.4.
- Workplan actions in the GitLab Duo Agentic Chat empty state [removed](https://gitlab.com/gitlab-org/gitlab/-/work_items/626672) in GitLab 19.5.

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
- **Ready for review**: The work item has a workplan.

## Set up workplan generation

Before you can [generate a workplan with GitLab Duo](#generate-a-workplan-with-gitlab-duo),
your project and top-level group must be set up to run the **Generate Workplan** flow.

Prerequisites:

- The work item must be an issue or a task in a project. You cannot generate a workplan
  for a work item in a group.
- [GitLab Duo turned on](../duo_agent_platform/turn_on_off.md#turn-gitlab-duo-on-or-off).
- Flow execution and foundational flows turned on for the top-level group, with the
  **Generate Workplan** flow selected. On GitLab Self-Managed, flow execution and
  foundational flows must also be turned on for the instance.
- The **Allow flow execution** and **Allow foundational flows** settings turned on
  for the project.

For the steps to change these settings, see
[turn foundational flows on or off](../duo_agent_platform/flows/foundational_flows/_index.md#turn-foundational-flows-on-or-off).

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

By default, the **Workplan** widget and the readiness level are hidden on a work item.
To show them, turn on planning for that work item.

Prerequisites:

- An issue or a task.
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

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/248543) in GitLab 19.3 [with a feature flag](../../administration/feature_flags/_index.md) named `duo_workplan_async_flow`. Disabled by default.
- Generating a workplan in GitLab Duo Chat [removed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/260695) in GitLab 19.6. Feature flag `duo_workplan_async_flow` removed.

{{< /history >}}

GitLab Duo generates the workplan with the **Generate Workplan** flow, which runs in the background.
When you [turn on planning](#turn-on-planning-for-a-work-item) for a work item,
GitLab Duo starts to generate a workplan.

Prerequisites:

- Workplan generation [set up](#set-up-workplan-generation).

To generate a workplan with GitLab Duo:

1. On the work item, in the **Workplan** widget, select **Generate**.
1. If GitLab Duo asks questions, answer them in the comment threads on the work item.
   Then, in the **Workplan** widget, select **Continue**.

GitLab Duo writes the workplan to the **Workplan** widget, and the status changes to
**Ready for review**.

The flow runs in the background, so you can leave the page while GitLab Duo works.
When GitLab Duo needs your input, you receive a to-do item and an email.

If the generation fails, in the **Workplan** widget, select **Try again**.

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

1. Go to the work item.
1. In the **Workplan** widget, select **View**.

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
- Workplan generation [set up](#set-up-workplan-generation).

To regenerate a workplan:

1. On the work item, in the **Workplan** widget, select **View**.
1. In the panel, select **More actions** ({{< icon name="ellipsis_v" >}}) > **Regenerate workplan**.
1. If GitLab Duo asks questions, answer them in the comment threads on the work item.
   Then, in the **Workplan** widget, select **Continue**.

GitLab Duo replaces the existing workplan with the new version.

## Delete a workplan

Prerequisites:

- Permission to edit the work item.

To delete a workplan:

1. On the work item, in the **Workplan** widget, select **View**.
1. In the panel, select **More actions** ({{< icon name="ellipsis_v" >}}) > **Delete workplan**.
1. In the confirmation dialog, select **Delete**.

This action cannot be undone.

## Readiness

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/248374) in GitLab 19.3 [with a feature flag](../../administration/feature_flags/_index.md) named `workplan_score`. Disabled by default.
- [Renamed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/259555) from confidence score to readiness score in GitLab 19.5.

{{< /history >}}

> [!flag]
> The availability of this feature is controlled by a feature flag.
> For more information, see the history.
> This feature is available for testing, but not ready for production use.

Readiness shows how ready a work item is for GitLab Duo to
[implement](#implement-a-workplan-with-gitlab-duo).
GitLab Duo evaluates how complete, clear, and well scoped the work item is,
and shows the result as a readiness level.

Prerequisites:

- Planning turned on for the work item.

In the **Workplan** widget on the work item, the readiness level appears as
**Low**, **Medium**, or **High**.
The readiness level appears only after GitLab Duo generates a workplan and
evaluates the work item.

To view feedback on how to improve readiness, select **Readiness details**
({{< icon name="information-o" >}}) next to the readiness level.
The feedback opens in a drawer and shows any suggested changes to the work item or its workplan.
To close the drawer, select **Readiness details** again.

To improve readiness, make the suggested changes.
For example, add requirements, acceptance criteria, and constraints to the work item
description and to the workplan steps.

## Decision log

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/249268) in GitLab 19.3 [with a feature flag](../../administration/feature_flags/_index.md) named `decision_log`. Disabled by default.

{{< /history >}}

> [!flag]
> The availability of this feature is controlled by a feature flag.
> For more information, see the history.
> This feature is available for testing, but not ready for production use.

The decision log is a record of the decisions made about a work item. It keeps the reason for
each decision next to the work item, so the history is not lost in chat or in comment threads.

The decision log is available on issues and tasks, and on custom work item types based on issues or tasks.
A work item does not need a workplan to have a decision log.

GitLab Duo adds a decision to the log when it settles an open question while it plans the work.
You can also record a decision yourself at any time.

Prerequisites:

- The Planner, Reporter, Security Manager, Developer, Maintainer, or Owner role for the project.

To open the decision log:

- On the work item, in the header, select **Decision log** ({{< icon name="log" >}}).

The button shows a count of the decisions on the work item.

### Record a decision manually

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/254465) in GitLab 19.5 [with a feature flag](../../administration/feature_flags/_index.md) named `decision_log`. Disabled by default.

{{< /history >}}

To record a decision manually:

1. On the work item, in the header, select **Decision log** ({{< icon name="log" >}}).
1. In the panel, select **New decision**.
1. Complete the fields. The required fields are **Decision**, **Decided by**, and **Context**.
1. Optional. In **Why**, explain why you chose this option over other options.
1. Optional. In **Source link**, add a link to where the discussion happened, such as Slack,
   Google Docs, or GitLab.
1. Select **Create decision**.

## Implement a workplan with GitLab Duo

When a workplan exists, GitLab Duo can implement it in a merge request. GitLab Duo treats
the workplan as the primary specification and uses the work item description and comments only for
additional context.

Prerequisites:

- GitLab Duo Agent Platform remote flows turned on.
- [Developer Flow](../project/merge_requests/developer.md) turned on for the top-level
  group and the project. For more information, see
  [turn foundational flows on or off](../duo_agent_platform/flows/foundational_flows/_index.md#turn-foundational-flows-on-or-off).

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

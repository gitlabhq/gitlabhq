---
stage: Agent Foundations
group: AI Catalog
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: Create and manage triggers to control when flows run in your project.
title: Triggers
---

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- Introduced in GitLab 18.3 [with a feature flag](../../../administration/feature_flags/_index.md) named `ai_flow_triggers`. Enabled by default.
- [Changed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/217634) in GitLab 18.8 to require an additional [flag](../../../administration/feature_flags/_index.md) named `ai_catalog_create_third_party_flows`. Disabled by default.
- [Generally available](https://gitlab.com/gitlab-org/gitlab/-/work_items/585273) in GitLab 18.8.

{{< /history >}}

> [!flag]
> To change the location of your flow configuration file, you must enable a feature flag.
> For more information, see the history.

A trigger determines when a flow or external agent runs.
A trigger cannot be created for a custom agent or foundational agent.

For example, you can specify flows to be triggered when you mention them
in a discussion, or when you assign them as a reviewer.

## Create a trigger

{{< history >}}

- **Assign** and **Assign reviewer** event types [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/567787) in GitLab 18.5.
- Pipeline events trigger event type [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/212797) in GitLab 18.9 as an [experiment](../../../policy/development_stages_support.md) with a [flag](../../../administration/feature_flags/_index.md) named `ai_flow_trigger_pipeline_hooks`. Disabled by default.
- **Merge request ready** trigger event type [introduced](https://gitlab.com/gitlab-org/gitlab/-/work_items/592454) in GitLab 19.0 with a [flag](../../../administration/feature_flags/_index.md) named `merge_request_ready_flow_trigger`. Disabled by default.
- **Merge request code conflict** trigger event type [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/234044) in GitLab 19.1.
- **Merge request** trigger event type with the **Approved** action [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/237081) in GitLab 19.1.
- Feature flag `ai_flow_trigger_pipeline_hooks` [removed](https://gitlab.com/gitlab-org/gitlab/-/work_items/587272) in GitLab 19.1.
- **Work item created** trigger event type [introduced](https://gitlab.com/gitlab-org/gitlab/-/work_items/599985) in GitLab 19.1.
- **Merge request ready** trigger event type [generally available](https://gitlab.com/gitlab-org/gitlab/-/work_items/598421) in GitLab 19.1. Feature flag `merge_request_ready_flow_trigger` removed.
- **Work item status changed** trigger event type [introduced](https://gitlab.com/gitlab-org/gitlab/-/work_items/599983) in GitLab 19.2.
- **Merge request ready** and **Merge request code conflict** event types [consolidated](https://gitlab.com/gitlab-org/gitlab/-/work_items/602777) into the **Merge request** event type as the **Marked ready** and **Merge conflict** actions in GitLab 19.2.
- Trigger creation form [changed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/248807) to add conditions one at a time in GitLab 19.3.
- **Merge request** trigger event type with the **Created** action [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/242698) in GitLab 19.4.
- **Status** filter for the **Work item** trigger event type with the **Status changed** action [introduced](https://gitlab.com/gitlab-org/gitlab/-/work_items/607577) in GitLab 19.4.

{{< /history >}}

> [!flag]
> The availability of this feature is controlled by a feature flag.
> For more information, see the history.

Prerequisites:

- You must have the Maintainer or Owner role for the project.

To create a trigger:

1. In the top bar, select **Search or go to** and find your project.
1. In the left sidebar, select **AI** > **Triggers**.
1. Select **New flow trigger**.
1. In **Description**, enter a description for the trigger.
1. In the **Conditions** section, for each condition that should start the trigger:
   1. Select **Add condition**, then select **On an event**.
   1. From the **Event** dropdown list, select a [trigger event type](#trigger-event-types).
   1. If the event type needs configuration, from the **Run when** dropdown list select one or
      more trigger event actions.
   1. Select **Add event**.
1. From the **Service account** dropdown list,
   select a user to be [the composite identity](../composite_identity.md).
1. For **Configuration source**, select one of the following:
   - **AI Catalog**: From the flows configured for this project,
     select a flow for the trigger to execute.
   - **Configuration path**: Enter the path to the flow configuration file
     (for example, `.gitlab/duo/flows/claude.yaml`).
     To view this option, the `ai_catalog_create_third_party_flows` flag must be enabled.
1. Optional. To give an event its own instructions, in the **Conditions** section, for that
   event select **Edit event** ({{< icon name="pencil" >}}). Enter the text in the **Goal**
   field, then select **Save**. For more information, see [Add a goal](#add-a-goal).
1. Select **Create flow trigger**.

The trigger now appears in **AI** > **Triggers**.

### Trigger event types

| Name            | Description                                                                           | Configuration |
|-----------------|---------------------------------------------------------------------------------------|------|
| Mention         | When the service account user is mentioned in a comment on an issue or merge request. | None |
| Assign          | When the service account user is assigned to an issue or merge request.               | None |
| Assign reviewer | When the service account user is assigned as a reviewer to a merge request.           | None |
| Pipeline events | When a pipeline changes state.                                                        | From the **Run when** dropdown list, select one or more of the following:<br>- **Running**<br>- **Passed**<br>- **Failed**<br>- **Canceled** |
| Merge request   | When a selected merge request action occurs.                                          | From the **Run when** dropdown list, select one of the following:<br>- **Approved**: When a merge request has all required approvals.<br>- **Created**: When someone creates a merge request, draft or ready, and GitLab generates its diff. GitLab syncs code owner approval rules against that diff before the flow runs, unless the merge request joins a merge train or GitLab cannot reload the diff.<br>- **Marked ready**: When a draft merge request is marked as ready for review.<br>- **Merge conflict**: When a merge request can no longer be merged due to a code conflict. |
| Work item       | When a selected work item action occurs.                                              | From the **Run when** dropdown list, select one of the following:<br>- **Created**: When a work item is created<br>- **Status changed**: When a work item's status changes. When **Status changed** is the only selected action, you can select one or more statuses to run the flow only when the work item changes to one of them. |

## Add a goal

{{< history >}}

- Goal for each condition [introduced](https://gitlab.com/gitlab-org/gitlab/-/work_items/627896) in GitLab 19.5 [with a flag](../../../administration/feature_flags/_index.md) named `ai_flow_trigger_goals`. Disabled by default.

{{< /history >}}

> [!flag]
> The availability of this feature is controlled by a feature flag.
> For more information, see the history.

A goal is text that tells the flow what to do. Add a goal to a condition when you want the flow
to do a specific task for that event. Two trigger events can run the same flow with different
goals.

Prerequisites:

- You must have the Maintainer or Owner role for the project.
- The trigger must use a flow that accepts a goal. Custom flows and external agents accept a
  goal, and so does a trigger that uses a configuration path. Foundational flows, such as
  Code Review, do not accept a goal.

To add a goal to a condition in an existing trigger:

1. In the top bar, select **Search or go to** and find your project.
1. In the left sidebar, select **AI** > **Triggers**.
1. For the trigger you want to change, select **More actions** ({{< icon name="ellipsis_v" >}}) > **Edit trigger**.
1. In the **Conditions** section, for the condition you want to change, select **Edit event** ({{< icon name="pencil" >}}).
1. In the **Goal** field, enter the goal. Use 4096 characters or fewer.
1. Select **Save**.
1. Select **Save changes**.

The goal appears under the condition in the **Conditions** section.

A goal belongs to one condition, not to the whole trigger. For a **Merge request** event, one
goal applies to every action that you select in **Run when**.

You can also add a goal when you [create a trigger](#create-a-trigger) or when you
[enable a flow](../flows/custom.md#enable-a-flow). In the trigger form, the **Goal** field
stays hidden until you set **Configuration source**. If you select **AI Catalog**, you must
also select a flow that accepts a goal.

### Write a goal

The goal goes in front of the information that the event supplies. The goal never replaces that
information. Do not repeat that information in the goal.

The flow also receives:

- For a mention event, the comment that the person wrote.
- For every other event, a short context block. The block gives the web address of the merge
  request, work item, or project. The block also gives the action that occurred.

> [!warning]
> The flow runs with the permissions of the service account. No person is present to answer
> questions from the flow. Write the goal so that the flow can complete it alone.

To write a goal that gets the result you want:

- Give the flow one clear task.
- Do not name the resource. The context block already names it.
- Give all the details that the flow needs. The flow cannot ask you for more.
- Say what the output must look like. For example, give the format or the maximum length.
- Ask only for work that the service account has permission to do.

The following table shows example goals.

| Event | Goal |
|-------|------|
| Mention | `Answer the question in a comment. Keep the reply under 200 words.` |
| Merge request, **Created** action | `Review the code changes and list any missing tests in a comment.` |
| Work item, **Created** action | `Add a severity label and a test plan.` |

## Edit a trigger

1. In the top bar, select **Search or go to** and find your project.
1. In the left sidebar, select **AI** > **Triggers**.
1. For the trigger you want to change, select **More actions** ({{< icon name="ellipsis_v" >}}) > **Edit trigger**.
1. Make the changes and select **Save changes**.

You can also edit a custom flow's trigger on its configuration page, under **Trigger conditions**.

## Turn a trigger on or off

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/work_items/598439) in GitLab 19.4.

{{< /history >}}

Turn off a trigger to disable it and retain its configuration. After you turn a trigger off,
it stops running automatically after its configured actions, and remains in the list of triggers.

1. In the top bar, select **Search or go to** and find your project.
1. In the left sidebar, select **AI** > **Triggers**.
1. For the trigger you want to turn on or off, on the right side, select the toggle.

You can also turn a custom flow's trigger on or off on its configuration page, under **Trigger conditions**.

## Delete a trigger

1. In the top bar, select **Search or go to** and find your project.
1. In the left sidebar, select **AI** > **Triggers**.
1. For the trigger you want to delete, select **More actions** ({{< icon name="ellipsis_v" >}}) > **Delete trigger**.
1. On the confirmation dialog, select **OK**.

You can also delete a custom flow's trigger on its configuration page, under **Trigger conditions**.

## Actions that don't initiate a trigger

All trigger event types require a human user to perform the triggering action.
A non-human user such as a bot user, service account user, or another flow, cannot activate a trigger.

This restriction applies to all [trigger event types](#trigger-event-types).
For example, a flow cannot trigger another flow by mentioning the service account in a comment.

## GitLab Credits consumption for triggered flows

A flow started by a trigger runs as the trigger's [service account](../../profile/service_accounts.md),
which makes the service account the billing subject for the flow's GitLab Credits consumption.
The human user who performed the triggering action provides the delegated authorization
context for the flow to run, but is not the billing subject.

Service accounts are non-human subjects and they do not receive included credits.
Their consumption is billed at the namespace from the Monthly Commitment Pool and
On-Demand credits. For more information about these types of credits, see [GitLab Credits](../../../subscriptions/gitlab_credits.md).

For example, a trigger runs a flow when a merge request receives all required approvals,
and the merge request requires three approvals. When the third approver approves the merge request,
the trigger runs the flow as the configured service account, and the credit consumption is
attributed to the service account rather than to the third approver.

This attribution applies to every trigger event type. For example, it also applies to flows
triggered by a pipeline state change, a work item status change, or a mention.

In the [GitLab Credits dashboard](../../../subscriptions/gitlab_credits_dashboard.md), this
credit consumption displays in the **Usage by user** tab as a row for the service account
with an **Automated flow** badge. It does not display under the human user who triggered the flow.

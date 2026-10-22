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

## Foundational flow triggers

A trigger runs only when its foundational flow is turned on for your group or project. For more information, see [turn foundational flows on or off](../flows/foundational_flows/_index.md#turn-foundational-flows-on-or-off).

Foundational flows can start in the following ways:

- Default triggers that GitLab adds when you turn on the flow.
- Triggers that you create for events the flow supports.
- Another way, such as when a security scan finishes.
  These flows don't use triggers, so you don't see them listed in **AI** > **Triggers**.

For details about how to start each flow, see the individual
[foundational flow documentation](../flows/foundational_flows/_index.md).

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
- **Type** filter for the **Work item** trigger event type [introduced](https://gitlab.com/gitlab-org/gitlab/-/work_items/633870) in GitLab 19.6.

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
   event select **Edit event** ({{< icon name="pencil" >}}). Enter the text in the
   **Instructions** field, then select **Save**. For more information, see
   [Add instructions](#add-instructions).
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
| Work item       | When a selected work item action occurs.                                              | From the **Run when** dropdown list, select one of the following:<br>- **Created**: When a work item is created<br>- **Status changed**: When a work item's status changes. When **Status changed** is the only selected action, you can select one or more statuses to run the flow only when the work item changes to one of them.<br><br>For both actions, from the **Type** dropdown list, you can select work item types to run the flow only for those types. When you select types, the **Status** dropdown list shows only the statuses of those types. If the selected types do not use a selected status, the list shows that status in a separate group, so that you can clear it. When you select no type, the same applies to a status that no type uses. |

### Work item type IDs

In the GraphQL API, the `filter` argument of the `aiFlowTriggerCreate` and `aiFlowTriggerUpdate`
mutations sets the work item type filter with a `work_item_type_id` rule.
The rule uses the `in` operator to run the flow only for the listed types,
or the `not_in` operator to run the flow for all other types.
The value is a list of work item type IDs.
The IDs are integers, for example `5`.
GitLab rejects a string such as `"5"`.
For example, this filter runs the flow only when the status of a task changes to `In dev`:

```json
{
  "work_item": {
    "rules": [
      { "field": "action", "operator": "in", "value": ["status_changed"] },
      { "field": "status.name", "operator": "in", "value": ["In dev"] },
      { "field": "work_item_type_id", "operator": "in", "value": [5] }
    ]
  }
}
```

The default work item types have the same ID on every GitLab instance:

| Work item type | ID  |
|----------------|-----|
| Issue          | `1` |
| Incident       | `2` |
| Test Case      | `3` |
| Requirement    | `4` |
| Task           | `5` |
| Objective      | `6` |
| Key Result     | `7` |
| Epic           | `8` |
| Ticket         | `9` |

Custom work item types have other IDs.
To find the ID of a type, query the `workItemTypes` field of the project.
The ID is the number at the end of the `id` of the type.

The trigger form shows and changes only `in` rules.
For a `not_in` rule, the **Type** dropdown list shows **Any type**, and the form keeps the rule.
If you change the types in the form, the form replaces the `not_in` rule.

## Add instructions

{{< history >}}

- Instructions for each condition [introduced](https://gitlab.com/gitlab-org/gitlab/-/work_items/627896) in GitLab 19.5 [with a flag](../../../administration/feature_flags/_index.md) named `ai_flow_trigger_goals`. Disabled by default.

{{< /history >}}

> [!flag]
> The availability of this feature is controlled by a feature flag.
> For more information, see the history.

Instructions are text that tells the flow what to do. Add instructions to a condition when you
want the flow to do a specific task for that event. Two trigger events can run the same flow
with different instructions.

Prerequisites:

- You must have the Maintainer or Owner role for the project.
- The trigger must use a flow that accepts instructions. If the flow does not accept them, the
  **Instructions** field does not appear.

To add instructions to a condition in an existing trigger:

1. In the top bar, select **Search or go to** and find your project.
1. In the left sidebar, select **AI** > **Triggers**.
1. For the trigger you want to change, select **More actions** ({{< icon name="ellipsis_v" >}}) > **Edit trigger**.
1. In the **Conditions** section, for the condition you want to change, select **Edit event** ({{< icon name="pencil" >}}).
1. In the **Instructions** field, enter the instructions. Use 4096 characters or fewer.
1. Select **Save**.
1. Select **Save changes**.

The instructions appear under the condition in the **Conditions** section.

Instructions belong to one condition, not to the whole trigger. For a **Merge request** event,
one set of instructions applies to every action that you select in **Run when**.

You can also add instructions when you [create a trigger](#create-a-trigger) or when you
[enable a flow](../flows/custom.md#enable-a-flow). In the trigger form, the **Instructions**
field stays hidden until you set **Configuration source**. If you select **AI Catalog**, you
must also select a flow that accepts instructions.

### Write instructions

The instructions go in front of the information that the event supplies. The instructions never
replace that information. Do not repeat that information in the instructions.

The flow also receives:

- For a mention event, the comment that the person wrote.
- For every other event, a short context block. The block gives the web address of the merge
  request, work item, or project. The block also gives the action that occurred.

> [!warning]
> The flow runs with the permissions of the service account. No person is present to answer
> questions from the flow. Write the instructions so that the flow can complete them alone.

To write instructions that get the result you want:

- Give the flow one clear task.
- Do not name the resource. The context block already names it.
- Give all the details that the flow needs. The flow cannot ask you for more.
- Say what the output must look like. For example, give the format or the maximum length.
- Ask only for work that the service account has permission to do.

The following table shows example instructions.

| Event | Instructions |
|-------|--------------|
| Mention | `Answer the question in a comment. Keep the reply under 200 words.` |
| Merge request, **Created** action | `Review the code changes and list any missing tests in a comment.` |
| Work item, **Created** action | `Add a severity label and a test plan.` |

## Change the work item when the session finishes

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/work_items/633112) in GitLab 19.6 [with flags](../../../administration/feature_flags/_index.md) named `ai_flow_trigger_status_on_finish` and `ai_flow_trigger_chaining`. Disabled by default.

{{< /history >}}

> [!flag]
> The availability of this feature is controlled by feature flags.
> For more information, see the history.

A trigger can change a work item after the session that the trigger started finishes.
Use this to move a work item to the next stage of your process, with no human action between
the stages.

You can set one or both of these settings:

- **Set work item status**: GitLab sets the work item to this status.
- **Mark merge requests as ready**: GitLab marks the draft merge requests that the session created
  as ready.
  If [automatic reviews](../flows/foundational_flows/code_review/_index.md#automatic-reviews)
  are on, GitLab then adds GitLab Duo Code Review as a reviewer.

If you set both, GitLab marks the merge requests as ready first.
If a merge request stays a draft, GitLab does not set the status.

Prerequisites:

- You must have the Maintainer or Owner role for the project.
- The trigger must have a **Work item** condition with **Status changed** as its only action,
  and at least one status.
  Until the condition meets these requirements, the settings are not available.

To change the work item when the session finishes:

1. In the top bar, select **Search or go to** and find your project.
1. In the left sidebar, select **AI** > **Triggers**.
1. For the trigger you want to change, select **More actions** ({{< icon name="ellipsis_v" >}}) > **Edit trigger**.
1. In the **Conditions** section, for the **Work item** condition, select **Edit event** ({{< icon name="pencil" >}}).
1. From the **Run when** dropdown list, select only **Status changed**.
1. From the **Status** dropdown list, select one or more statuses, then select **Save**.
1. Under **When the session finishes**, set one or both:
   - From the **Set work item status** dropdown list, select a status.
   - Select the **Mark merge requests as ready** checkbox.
1. Select **Save changes**.

You can also set these settings when you [create a trigger](#create-a-trigger).

If you later add the **Created** action, remove the last status, or remove the **Work item** condition, GitLab clears the settings.
If you change the types so that they do not have the status of **Set work item status**,
GitLab clears that status.

### When GitLab applies the settings

GitLab applies the settings only when all of these conditions are true:

- The session has the `finished` status.
  A stopped session, a failed session, or a session that waits for input changes nothing.
- The trigger is turned on.
- A work item event started the session.
- A human user started this session, or the first session of its [chain](#chain-triggers),
  with a **Mention**, **Assign**, or **Work item** event.
- The work item still has one of the statuses of the trigger.
  If the status changes to a status that the trigger does not run on while the session runs,
  GitLab changes nothing.
  This also applies when the flow sets the status of its own work item.
- The service account of the session enforces composite identity.
- The service account and the user who started the session can both update the work item
  and the merge requests.

GitLab does not set a status that the work item type does not have.

### Chain triggers

GitLab writes the changes as the composite identity of the session.
For this reason, GitLab treats the status change as an event that a flow caused.
The status change can start another trigger that runs on the new status.
The finished session becomes the parent of the next session, inside the chain depth and
breadth limits.

> [!warning]
> Do not configure triggers whose statuses form a cycle. For example, trigger A runs on status X
> and sets status Y, and trigger B runs on status Y and sets status X.
> The chain limits stop a cycle, but each session in the cycle still runs.

To keep a human decision between two stages, set the status to one that no trigger runs on,
for example `Plan ready`.
A user then moves the work item to the status that starts the next stage.

The following table shows two triggers that move a work item through three statuses with no
human action between the stages.

| Trigger | Runs when the status changes to | Flow | Set work item status | Mark merge requests as ready |
|---------|---------------------------------|------|----------------------|------------------------------|
| A | `Planning` | Generate Workplan | `Ready for development` | No |
| B | `Ready for development` | GitLab Duo Developer | `In review` | Yes |

### Known issues

- A session can finish without the work done. For example, GitLab Duo Developer can decide
  that no code change is necessary and open no merge request. GitLab still sets the status.
  If your flow can stop early, make it end as failed or as waiting for input.
  GitLab then does not set the status.
- If the status that the trigger sets is also one of the statuses that the trigger runs on,
  the change can start the trigger again. The form shows a warning for this configuration.

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
The status change from the settings of a trigger is an exception.
For more information, see [chain triggers](#chain-triggers).

## GitLab Credits consumption for triggered flows

A flow started by a trigger runs as the trigger's service account with [composite identity](../composite_identity.md).
The flow's usage is billed to the namespace, not to the user who performed the triggering action.

For example, a trigger runs a flow when a merge request receives all required approvals,
and the merge request requires three approvals. When the third approver approves the merge request,
the trigger runs the flow as the configured service account, and the usage is billed
to the namespace rather than to the third approver.

This billing applies to every trigger event type, including a pipeline state change,
a work item status change, or a mention.

For more information, see [billing subjects for credit usage](../../../subscriptions/gitlab_credits.md#billing-subjects-for-credit-usage).

## Troubleshooting

### Error: `Event types contains event types not supported`

When you create or edit a foundational flow trigger, you might get this error:

```plaintext
Event types contains event types not supported by this foundational flow
```

The trigger includes an event type that the flow does not accept.
To resolve this error, check the flow's documentation for the events it supports, then do one of the following:

- If the flow uses triggers, edit the trigger to remove the events the flow
  does not support. For example, Fix CI/CD Pipeline accepts only Pipeline events.
- If the flow starts another way, delete the trigger because the flow doesn't need one.
  For example, [SAST False Positive Detection](../../application_security/vulnerabilities/false_positive_detection.md)
  runs after a security scan.

### Service account shows `No triggers for this event`

When you assign a service account to a merge request or request a review from it,
the service account might be disabled with the message `No triggers for this event`.
In mention autocomplete, a service account without a mention trigger doesn't appear.
In each case, the project has no trigger for that service account and event:

- The assignee menu requires **Assign**.
- The reviewer menu requires **Assign reviewer**.
- Mention autocomplete requires **Mention**.

To resolve this issue:

1. In your project, select **AI** > **Triggers**.
1. Check for a trigger that uses the service account and the event you want.
1. Check the flow's documentation to confirm that the flow supports that event.
1. If the flow supports the event, create or edit a trigger to include it.
   Otherwise, use the method described in the flow's documentation.

An event that you can save in a trigger is not necessarily an event the flow can run.
For example, Developer cannot run from **Pipeline events**.
Use a supported event rather than adding an event only to make a service account selectable.

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
1. From the **Event types** dropdown list, select:
   - One or more [trigger event types](#trigger-event-types).
   - If needed for the trigger event type, a trigger event action.
1. From the **Service account** dropdown list,
   select a user to be [the composite identity](../composite_identity.md).
1. For **Configuration source**, select one of the following:
   - **AI Catalog**: From the flows configured for this project,
     select a flow for the trigger to execute.
   - **Configuration path**: Enter the path to the flow configuration file
     (for example, `.gitlab/duo/flows/claude.yaml`).
     To view this option, the `ai_catalog_create_third_party_flows` flag must be enabled.
1. Select **Create flow trigger**.

The trigger now appears in **AI** > **Triggers**.

### Trigger event types

| Name            | Description                                                                           | Configuration |
|-----------------|---------------------------------------------------------------------------------------|------|
| Mention         | When the service account user is mentioned in a comment on an issue or merge request. | None |
| Assign          | When the service account user is assigned to an issue or merge request.               | None |
| Assign reviewer | When the service account user is assigned as a reviewer to a merge request.           | None |
| Pipeline events | When a pipeline changes state.                                                        | From the **Trigger when** dropdown list, select one or more of the following:<br>- **Running**<br>- **Passed**<br>- **Failed**<br>- **Canceled** |
| Merge request   | When a selected merge request action occurs.                                          | From the **Trigger when** dropdown list, select one of the following:<br>- **Approved**: When a merge request has all required approvals<br>- **Marked ready**: When a draft merge request is marked as ready for review<br>- **Merge conflict**: When a merge request can no longer be merged due to a code conflict |
| Work item       | When a selected work item action occurs.                                              | From the **Trigger when** dropdown list, select one of the following:<br>- **Created**: When a work item is created<br>- **Status changed**: When a work item's status changes |

## Edit a trigger

1. In the top bar, select **Search or go to** and find your project.
1. In the left sidebar, select **AI** > **Triggers**.
1. For the trigger you want to change, select **Edit flow trigger** ({{< icon name="pencil" >}}).
1. Make the changes and select **Save changes**.

## Delete a trigger

1. In the top bar, select **Search or go to** and find your project.
1. In the left sidebar, select **AI** > **Triggers**.
1. For the trigger you want to change, select **Delete flow trigger** ({{< icon name="remove" >}}).
1. On the confirmation dialog, select **OK**.

---
stage: AI-powered
group: Workflow Catalog
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Custom flows
---

{{< details >}}

- Tier: Premium, Ultimate
- Add-on: GitLab Duo Core, Pro, or Enterprise
- Offering: GitLab.com, GitLab Self-Managed
- Status: Experiment

{{< /details >}}

{{< collapsible title="Model information" >}}

- LLM: Anthropic [Claude Sonnet 4](https://www.anthropic.com/claude/sonnet)

{{< /collapsible >}}

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/578228) in GitLab 18.7 [with a flag](../../../administration/feature_flags/_index.md) named `ai_catalog_flows`. Disabled by default.

{{< /history >}}

{{< alert type="flag" >}}

The availability of this feature is controlled by a feature flag.
For more information, see the history.

{{< /alert >}}

Custom flows are AI-powered workflows you create and configure to
automate complex, multi-step tasks across your GitLab projects.

## Flow visibility

When you create a custom flow, you select a project to manage it and choose whether the flow is public or private.

Public flows:

- Can be viewed by anyone on the instance and can be enabled in any project that meets the prerequisites.

Private flows:

- Can be viewed only by members of the managing project who have at least the Developer role, and by users with the Owner role for the top-level group.
- Cannot be enabled in projects other than the managing project, or in groups other than the top-level group.

You cannot change a private flow to public if the flow is currently enabled.

## View the flows for your project

Prerequisites:

- You must have at least the Developer role for the project.

To view a list of flows associated with your project:

1. On the left sidebar, select **Search or go to** and find your project. If you've [turned on the new navigation](../../interface_redesign.md#turn-new-navigation-on-or-off), this field is on the top bar.
1. Select **Automate** > **Flows**.
   - To view flows enabled in the project, select the **Enabled** tab.
   - To view flows managed by the project, select the **Managed** tab.

Select a flow to view its details.

## Create a flow

Prerequisites:

- You must have at least the Maintainer role for the project.

To create a flow:

1. On the left sidebar, select **Search or go to** and find your project. If you've [turned on the new navigation](../../interface_redesign.md#turn-new-navigation-on-or-off), this field is on the top bar.
1. Select **Automate** > **Flows**.
1. Select **New flow**.
1. Under **Basic information**:
   1. In **Display name**, enter a name.
   1. In **Description**, enter a description.
1. Under **Visibility & access**, for **Visibility**, select **Private** or **Public**.
1. Under **Configuration**:
   1. Select **Flow**.
   1. In the editor, enter your flow configuration.
      To learn how to write custom flow YAML, see the [flow registry framework documentation](https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/-/blob/main/docs/flow_registry/v1.md).
1. Select **Create flow**.

The flow appears in the AI Catalog.

## Enable a flow

Enable a flow to trigger it from an issue, merge request, or discussion.
To enable a flow, you must:

1. Enable it in a top-level group.
1. Enable it in the project you want to use it in.

### Enable in a top-level group

Prerequisites:

- You must have the Owner role for the group.

To enable a flow in a top-level group:

1. On the left sidebar, select **Search or go to** > **Explore**. If you've [turned on the new navigation](../../interface_redesign.md#turn-new-navigation-on-or-off), this field is on the top bar.
1. Select **AI Catalog**, then select the **Flows** tab.
1. Select the flow you want to enable.
1. In the upper-right corner, select **Enable in group**.
1. From the dropdown list, select the group you want to enable the flow in.
1. Select **Enable**.

The flow appears in the group's **Automate** > **Flows** page.

### Enable in a project

Prerequisites:

- You must have at least the Maintainer role for the project.
- The flow must be enabled in the project's top-level group.

To enable a flow in a project:

1. On the left sidebar, select **Search or go to** and find your project. If you've [turned on the new navigation](../../interface_redesign.md#turn-new-navigation-on-or-off), this field is on the top bar.
1. Select **Automate** > **Flows**.
1. In the upper-right corner, select **Enable flow from group**.
1. From the dropdown list, select the flow you want to enable.
1. For **Add triggers**, select which events trigger the flow:
   - **Mention**: When the service account user is mentioned
     in a comment on an issue or merge request.
   - **Assign**: When the service account user is assigned
     to an issue or merge request.
   - **Assign reviewer**: When the service account user is assigned
     as a reviewer to a merge request.
1. Select **Enable**.

The flow appears in the project's **Automate** > **Flows** list.

### Disable a flow

Prerequisites:

- For groups, you must have the Owner role.
- For projects, you must have at least the Maintainer role.

To disable a flow:

1. On the left sidebar, select **Search or go to** and find your group or project. If you've [turned on the new navigation](../../interface_redesign.md#turn-new-navigation-on-or-off), this field is on the top bar.
1. Select **Automate** > **Flows**.
1. Find the flow you want to remove and select **Actions** ({{< icon name="ellipsis_v" >}}) > **Disable**.
1. On the confirmation dialog, select **Disable**.

The flow no longer appears in the project or group, and can't be run. Any service accounts or triggers associated with the flow are also removed.

## Create a trigger

You must now [create a trigger](../triggers/_index.md), which determines when the flow runs.

For example, you can specify the flow to be triggered when you mention the flow service account user in a discussion,
or when you assign the service account as a reviewer.

When you enable a flow in a project, you also create triggers.

## Use a flow

Prerequisites:

- You must have at least the Developer role for the project.
- The flow must be enabled in the project.

To use a flow:

1. In your project, open an issue, merge request, or epic.
1. To trigger the flow, mention, assign, or request a review from the flow service account user. By default, the user has the name `ai-<flow>-<group>`.

   For example, if you enable a flow called `Code review flow` in the `GitLab Duo` group, the service account user is `ai-code-review-flow-gitlab-duo`.
1. After the flow has completed the task, you see a confirmation, and either a ready-to-merge change or an inline comment.

## Duplicate a flow

To make changes to a flow without overwriting the original, create a copy of an existing flow.

Prerequisites:

- You must have at least the Maintainer role for the project.

To duplicate a flow:

1. On the left sidebar, select **Search or go to** > **Explore**. If you've [turned on the new navigation](../../interface_redesign.md#turn-new-navigation-on-or-off), this field is on the top bar.
1. Select **AI Catalog**, then select the **Flows** tab.
1. Select the flow you want to duplicate.
1. In the upper-right corner, select **Actions** ({{< icon name="ellipsis_v" >}}) > **Duplicate**.
1. Optional. Edit any fields you want to change.
1. Select **Create flow**.

## Manage flows

Edit a flow to change its configuration, or delete it to remove it from the AI Catalog.

Prerequisites:

- You must be a member of the managing project and have at least the Maintainer role.

1. On the left sidebar, select **Search or go to** > **Explore**. If you've [turned on the new navigation](../../interface_redesign.md#turn-new-navigation-on-or-off), this field is on the top bar.
1. Select **AI Catalog**, then select the **Flows** tab.
1. Select the flow you want to manage.
   - To edit a flow:
     1. In the upper-right corner, select **Edit**.
     1. Edit any fields you want to change, then select **Save changes**.
   - To delete a flow:
     1. In the upper-right corner, select **Actions** ({{< icon name="ellipsis_v" >}}) > **Delete**.
     1. On the confirmation dialog, select **Delete**.

## Report a flow

You can report an flow if it contains potentially offensive material or poses a risk to your organization.

To report a flow:

1. On the left sidebar, select **Search or go to** > **Explore**. If you've [turned on the new navigation](../../interface_redesign.md#turn-new-navigation-on-or-off), this field is on the top bar.
1. Select **AI Catalog**, then select the **Flows** tab.
1. Select the flow you want to report.
1. In the upper-right corner, select **Actions** ({{< icon name="ellipsis_v" >}}) > **Report to admin**.
1. Complete the abuse report, then select **Submit**.

An administrator is notified and can choose to hide or delete the flow.

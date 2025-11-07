---
stage: AI-powered
group: Agent Foundations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Triggers
---

{{< details >}}

- Tier: Premium, Ultimate
- Add-on: GitLab Duo Core, Pro, or Enterprise
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Status: Experiment

{{< /details >}}

{{< history >}}

- Introduced in GitLab 18.3 [with a flag](../../../administration/feature_flags/_index.md) named `ai_flow_triggers`. Enabled by default.

{{< /history >}}

A trigger determines when a flow runs.

You specify the service account that runs the flow, and which conditions make the flow run.

For example, you can specify flows to be triggered when you mention a service account
in a discussion, or when you assign the service account as a reviewer.

## Create a trigger

{{< history >}}

- **Assign** and **Assign reviewer** event types [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/567787) in GitLab 18.5.

{{< /history >}}

Prerequisites:

- You must have at least the Maintainer role for the project.

To create a trigger:

1. On the left sidebar, select **Search or go to** and find your project. If you've [turned on the new navigation](../../interface_redesign.md#turn-new-navigation-on-or-off), this field is on the top bar.
1. Select **Automate** > **Flow triggers**.
1. Select **New flow trigger**.
1. In **Description**, enter a description for the trigger.
1. From the **Event types** dropdown list, select one or more event types:
   - **Mention**: When the service account user is mentioned
     in a comment on an issue or merge request.
   - **Assign**: When the service account user is assigned
     to an issue or merge request.
   - **Assign reviewer**: When the service account user is assigned
     as a reviewer to a merge request.
1. From the **Service account user** dropdown list,
   select the service account user.
1. For **Configuration source**, select one of the following:
   - **AI Catalog**: From the flows configured for this project,
     select a flow for the trigger to execute.
   - **Configuration path**: Enter the path to the flow configuration file
     (for example, `.gitlab/duo/flows/claude.yaml`).
1. Select **Create flow trigger**.

The trigger now appears in **Automate** > **Flow triggers**.

### Edit a trigger

1. On the left sidebar, select **Search or go to** and find your project. If you've [turned on the new navigation](../../interface_redesign.md#turn-new-navigation-on-or-off), this field is on the top bar.
1. Select **Automate** > **Flow triggers**.
1. For the trigger you want to change, select **Edit flow trigger** ({{< icon name="pencil" >}}).
1. Make the changes and select **Save changes**.

### Delete a trigger

1. On the left sidebar, select **Search or go to** and find your project. If you've [turned on the new navigation](../../interface_redesign.md#turn-new-navigation-on-or-off), this field is on the top bar.
1. Select **Automate** > **Flow triggers**.
1. For the trigger you want to change, select **Delete flow trigger** ({{< icon name="remove" >}}).
1. On the confirmation dialog, select **OK**.

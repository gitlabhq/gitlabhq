---
stage: Agent Foundations
group: AI Catalog
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Custom flows
---

{{< details >}}

- Tier: [Free](../../../subscriptions/gitlab_credits.md#for-the-free-tier), Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated
{{< /details >}}

{{< collapsible title="Model information" >}}

- LLM: Anthropic [Claude Sonnet 4](https://www.anthropic.com/claude/sonnet)

{{< /collapsible >}}

{{< history >}}

- Introduced as an [experiment](../../../policy/development_stages_support.md) in GitLab 18.4 [with a feature flag](../../../administration/feature_flags/_index.md) named `ai_catalog_flows`. Disabled by default.
- Changed to [beta](../../../policy/development_stages_support.md) in GitLab 18.7.
- [Enabled on GitLab.com](https://gitlab.com/gitlab-org/gitlab/-/issues/569060) in GitLab 18.7.
- [Enabled on GitLab Self-Managed and GitLab Dedicated](https://gitlab.com/gitlab-org/gitlab/-/work_items/569060) in GitLab 18.8.
- Feature flag `ai_catalog_flows` [enabled by default](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/216969) in GitLab 18.8.
- Pipeline events trigger [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/212797) in GitLab 18.9 as an [experiment](../../../policy/development_stages_support.md) with a [flag](../../../administration/feature_flags/_index.md) named `ai_flow_trigger_pipeline_hooks`. Disabled by default.
- Enabling directly in projects as a maintainer [introduced](https://gitlab.com/groups/gitlab-org/-/work_items/20743) in GitLab 18.10 [with a feature flag](../../../administration/feature_flags/_index.md) named `ai_catalog_project_level_enablement`. Enabled on GitLab.com, GitLab Self-Managed, and GitLab Dedicated by default.
- Available on the Free tier on GitLab.com with GitLab Credits in GitLab 18.10.
- Feature flag `ai_catalog_project_level_enablement` removed in GitLab 18.11.
- **Merge request ready** trigger event type [introduced](https://gitlab.com/gitlab-org/gitlab/-/work_items/592454) in GitLab 19.0 with a [flag](../../../administration/feature_flags/_index.md) named `merge_request_ready_flow_trigger`. Disabled by default.
- **Merge request code conflict** trigger event type [introduced](https://gitlab.com/gitlab-org/gitlab/-/work_items/592455) in GitLab 19.1.
- **Merge request** trigger event type with the **Approved** action [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/237081) in GitLab 19.1.
- Feature flag `ai_flow_trigger_pipeline_hooks` [removed](https://gitlab.com/gitlab-org/gitlab/-/work_items/587272) in GitLab 19.1.
- **Work item created** trigger event type [introduced](https://gitlab.com/gitlab-org/gitlab/-/work_items/599985) in GitLab 19.1.
- **Merge request ready** trigger event type [generally available](https://gitlab.com/gitlab-org/gitlab/-/work_items/598421) in GitLab 19.1. Feature flag `merge_request_ready_flow_trigger` removed.
- **Work item status changed** trigger event type [introduced](https://gitlab.com/gitlab-org/gitlab/-/work_items/599983) in GitLab 19.2.
- Feature flag `ai_catalog_flows` [removed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/239459) in GitLab 19.2.
- Changed to [generally available](https://gitlab.com/gitlab-org/gitlab/-/work_items/602415) in GitLab 19.2.

{{< /history >}}

Custom flows are AI-powered workflows you create and configure to
automate complex, multi-step tasks across your GitLab projects.

## Prerequisites

- Meet the [prerequisites for the GitLab Duo Agent Platform](../_index.md#prerequisites).
- Have [beta and experimental features turned on](../turn_on_off.md#turn-on-beta-and-experimental-features).
- Have [custom flows turned on](#turn-custom-flows-on-or-off).

## Flow visibility

{{< history >}}

- Roles that can view private flows [expanded](https://gitlab.com/gitlab-org/gitlab/-/work_items/582507) in GitLab 18.7.

{{< /history >}}

When you create a custom flow, you select a project to manage it and choose whether the flow is public or private.

Public flows:

- Can be viewed by anyone on the instance and can be enabled in any project that meets the prerequisites.

Private flows:

- Can be viewed only by:
  - Members of the managing project who have the Guest, Planner, Reporter, Developer,
    Maintainer, or Owner role.
  - Users with the Owner role for the top-level group.
- Cannot be enabled in projects other than the managing project, or in groups
  other than the top-level group.

You cannot change a public flow to private if the flow is enabled.

## View the flows for your project

Prerequisites:

- You must have the Developer, Maintainer, or Owner role for the project.

To view a list of flows associated with your project:

1. In the top bar, select **Search or go to** and find your project.
1. In the left sidebar, select **AI** > **Flows**.
   - To view flows enabled in the project, select the **Enabled** tab.
   - To view flows managed by the project, select the **Managed** tab.

Select a flow to view its details.

## Create a flow

You can create a flow from a project, or by using the AI Catalog.

> [!note]
> You cannot define a custom flow to call a specific custom agent from a project
> or the AI Catalog. Custom flows create and use their own agents based
> on their YAML configuration.

Prerequisites:

- You must have the Maintainer or Owner role for the project.

{{< tabs >}}

{{< tab title="From a project" >}}

To create a flow:

1. In the top bar, select **Search or go to** and find your project.
1. In the left sidebar, select **AI** > **Flows**.
1. Select **New flow**.
1. Under **Basic information**:
   1. In **Display name**, enter a name.
   1. In **Description**, enter a description.
1. Under **Visibility & access**, for **Visibility**, select **Private** or **Public**.
1. Under **Configuration**:
   1. Select **Flow**.
   1. In the editor, enter your flow configuration:

      - For more information on the YAML syntax and schema, see [custom flow YAML schema](custom_flows_schema.md).
1. Select **Create flow**.

{{< /tab >}}

{{< tab title="From the AI Catalog" >}}

1. In the top bar, select **Search or go to** > **Explore**.
1. Select **AI Catalog**, then select the **Flows** tab.
1. Select **New flow**.
1. Under **Basic information**:
   1. In **Display name**, enter a name.
   1. In **Description**, enter a description.
1. Under **Visibility & access**, for **Visibility**, select **Private** or **Public**.
1. Under **Configuration**:
   1. Select **Flow**.
   1. In the editor, enter your flow configuration:

      - For more information on the YAML syntax and schema, see [custom flow YAML schema](custom_flows_schema.md).
1. Select **Create flow**.

{{< /tab >}}

{{< /tabs >}}

The flow appears in the AI Catalog.

## Enable a flow

{{< history >}}

- Enabling a public flow for multiple projects [introduced](https://gitlab.com/gitlab-org/gitlab/-/work_items/600526) in GitLab 19.2 [with a feature flag](../../../administration/feature_flags/_index.md) named `ai_catalog_bulk_item_consumer_create`. Enabled by default.

{{< /history >}}

> [!flag]
> The availability of this feature is controlled by a feature flag.
> For more information, see the history.

Enable a flow to trigger it from an issue, merge request, or discussion.

When you enable a flow in a project:

- The flow is enabled in the top-level group for that project at the same time.
- You add a [trigger](../triggers/_index.md) to specify which events trigger the
  flow. Some of the trigger events involve the service account user. For more
  information, see [composite identity](../composite_identity.md).

Prerequisites:

- You must have the Maintainer or Owner role for the project.

{{< tabs >}}

{{< tab title="From the managing project" >}}

To enable a flow:

1. In the top bar, select **Search or go to** and find your project.
1. In the left sidebar, select **AI** > **Flows**.
1. Select the **Managed** tab, then select the flow you want to enable.
1. In the upper-right corner, select **Enable**.
1. Under **Project**, select the project you want to enable the flow in.
1. For **Add triggers**, select:
   - The [event types that trigger the flow](../triggers/_index.md#trigger-event-types).
   - If needed for the trigger event type, a trigger event action.
1. Select **Enable**.

{{< /tab >}}

{{< tab title="From the AI Catalog" >}}

To enable a flow:

1. In the top bar, select **Search or go to** > **Explore**.
1. Select **AI Catalog**, then select the **Flows** tab.
1. Select the flow you want to enable.
1. In the upper-right corner, select **Enable**.
1. Under **Project**, select the project you want to enable the flow in.

   To enable a public flow for multiple projects, from the **Project** dropdown list,
   select the relevant projects. You can select up to 100 projects.

1. For **Add triggers**, select:
   - The [event types that trigger the flow](../triggers/_index.md#trigger-event-types).
   - If needed for the trigger event type, a trigger event action.
1. Select **Enable**.

{{< /tab >}}

{{< /tabs >}}

The flow appears in the group and project **AI** > **Flows** pages.
Members of any project in the top-level group can now enable the flow in their project.

A service account is created in the group. The name of the account
follows this naming convention: `ai-<flow>-<group>`.

### Enable in a project

If a flow is already enabled in a top-level group, you can enable it in the group's projects.

Prerequisites:

- You must have the Maintainer or Owner role for the project.
- The flow must be enabled in the project's top-level group.

To enable a flow in a project:

1. In the top bar, select **Search or go to** and find your project.
1. In the left sidebar, select **AI** > **Flows**.
1. In the upper-right corner, select **Enable flow from group**.
1. From the dropdown list, select the flow you want to enable.
1. For **Add triggers**, select:
   - The [event types that trigger the flow](../triggers/_index.md#trigger-event-types).
   - If needed for the trigger event type, a trigger event action.
1. Select **Enable**.

The flow appears in the project's **AI** > **Flows** list.

The top-level group's service account is added to the project.
This account is assigned the Developer role.

## Disable a flow

Prerequisites:

- For groups, you must have the Maintainer or Owner role.
- For projects, you must have the Maintainer or Owner role.

To disable a flow:

1. In the top bar, select **Search or go to** and find your group or project.
1. Select **AI** > **Flows**.
1. Find the flow you want to remove and select **Actions** ({{< icon name="ellipsis_v" >}}) > **Disable**.
1. On the confirmation dialog, select **Disable**.

The flow no longer appears in the project or group, and can't be run. Any service accounts or triggers associated with the flow are also removed.

## Use a flow

Prerequisites:

- You must have the Developer, Maintainer, or Owner role for the project.
- The flow must be enabled in the project.

To use a flow:

1. In your project, open an issue, merge request, or epic.
1. To trigger the flow, mention, assign, or request a review from the flow service account user. By default, the user has the name `ai-<flow>-<group>`.

   For example, if you enable a flow called `Security scanner` in the `GitLab Duo` group, the service account user is `ai-security-scanner-gitlab-duo`.
1. After the flow has completed the task, you see a confirmation, and either a ready-to-merge change or an inline comment.

> [!warning]
> The service account can access all projects that both:
>
> - You have access to.
> - The flow has been added to.

## Duplicate a flow

To make changes to a flow without overwriting the original, create a copy of an existing flow.

Prerequisites:

- You must have the Maintainer or Owner role for the project.

To duplicate a flow:

1. In the top bar, select **Search or go to** > **Explore**.
1. Select **AI Catalog**, then select the **Flows** tab.
1. Select the flow you want to duplicate.
1. In the upper-right corner, select **Actions** ({{< icon name="ellipsis_v" >}}) > **Duplicate**.
1. Optional. Edit any fields you want to change.
1. Select **Create flow**.

## Edit a flow

Edit a flow to change its configuration.

Prerequisites:

- You must be a member of the managing project and have the Maintainer or Owner role.

1. In the top bar, select **Search or go to** and find your group or project.
1. Select **AI** > **Flows**.
1. Select the flow you want to edit.
1. In the upper-right corner, select **Edit**.
1. Edit any fields you want to change, then select **Save changes**.

## Hide a flow

Hide a flow to remove it from the AI Catalog.

After you hide a flow, users can't enable it. However, they can still trigger it in the groups and projects it is already enabled in.

Prerequisites:

- You must be a member of the managing project and have the Maintainer or Owner role.

To hide a flow:

1. In the top bar, select **Search or go to** and find your group or project.
1. Select **AI** > **Flows**.
1. Find the flow you want to hide and select **Actions** ({{< icon name="ellipsis_v" >}}) > **Hide**.
1. In the confirmation dialog, select **Confirm**.

## Delete a flow

Delete a flow to permanently remove it from the instance.

Prerequisites:

- You must be an administrator.

1. In the top bar, select **Search or go to** and find your group or project.
1. Select **AI** > **Flows**.
1. Find the flow you want to delete and select **Actions** ({{< icon name="ellipsis_v" >}}) > **Delete**.
1. In the confirmation dialog, select **Delete**.

## Group sharing and flows

When you enable a flow in a group, a related service account is automatically created. The service account:

- Uses [composite identity authentication](../composite_identity.md) to ensure that the flow can never access more than the user who runs the flow.
- Is added as a member to any project under the top-level group that enables the flow, so the flow can't access resources outside that group.
- Is granted access to any additional groups that are shared with the top-level group. The service account is treated like any other group member for group sharing.

> [!note]
> Sharing flow service accounts across multiple top-level groups can create unintended access
> permissions and security risks.

## Turn custom flows on or off

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/work_items/594615) in GitLab 19.0.

{{< /history >}}

By default, custom flows are turned on.
You can turn them on or off for a top-level group or for an instance.

When custom flows are turned off:

- Users cannot create, enable, disable, or execute custom flows.
- Existing custom flows are no longer visible
  in the project under **AI** > **Flows** > **Enabled**.
- Custom flows created in the project appear
  under **AI** > **Flows** > **Managed**, but cannot be executed.
- [Foundational flows](foundational_flows/_index.md) remain available.

{{< tabs >}}

{{< tab title="GitLab.com" >}}

Prerequisites:

- You must have the Owner role for the group.

1. In the top bar, select **Search or go to** and find your group.
1. In the left sidebar, select **Settings** > **GitLab Duo**.
1. Select **Change configuration**.
1. Under **Custom and external agents and flows**, select or clear the
   **Allow custom flows** checkbox.
1. Select **Save changes**.

This setting cascades to all subgroups in the group.

{{< /tab >}}

{{< tab title="GitLab Self-Managed" >}}

Prerequisites:

- You must be an administrator.

1. In the upper-right corner, select **Admin**.
1. In the left sidebar, select **GitLab Duo**.
1. Select **Change configuration**.
1. Under **Custom and external agents and flows**, select or clear the
   **Allow custom flows** checkbox.
1. Select **Save changes**.

When the instance-level setting is turned off,
group-level settings cannot override it.

{{< /tab >}}

{{< /tabs >}}

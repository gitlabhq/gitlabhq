---
stage: AI-powered
group: Agent Foundations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: View and manage the status and execution data for agents and flows you have run.
title: Sessions
---

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Sessions show the status and execution data for the agents and flows you've run.

Sessions are created by GitLab Duo Agentic Chat and foundational flows in the IDE or UI. Examples include:

- Flows that are executed on a runner, like the [Fix your CI/CD Pipeline Flow](../flows/foundational_flows/fix_pipeline.md).
  These sessions are visible in the UI under **AI** > **Sessions**.
- Flows that run in the IDE, like the [Software development Flow](../flows/foundational_flows/software_development.md).
  These sessions are visible in the IDE, on the **Flows** tab, under **Sessions**.
- Sessions created by GitLab Duo Chat. These sessions are visible on the right sidebar
  by selecting **GitLab Duo Chat history**.
- Flows that are invoked by triggers. These sessions are visible in the UI under **AI** > **Sessions**.

## View sessions for your project

Prerequisites:

- You must have the Developer, Maintainer, or Owner role for the project.

To view sessions for your project:

1. In the top bar, select **Search or go to** and find your project.
1. In the left sidebar, select **AI** > **Sessions**.
1. Select any session to view more details.

## View sessions you've triggered

To view sessions you've triggered:

1. In the right sidebar, select **GitLab Duo sessions**.
1. Select any session to view more details.
1. Optional. Filter the details to show all logs or a concise subset only.

## GitLab Duo Agentic Chat sessions

Because chats are interactive, they require a clearer separation in the UI.
You can think of the Chat history as a filtered view of sessions that exists
exclusively for Chats.

To browse and switch Chat sessions in the GitLab Duo CLI, see [switch sessions](../../gitlab_duo_cli/_index.md#switch-sessions).

## Cancel a running session

You can cancel a session that is running or waiting for input. To cancel a session:

1. In the top bar, select **Search or go to** and find your project.
1. In the left sidebar, select **AI** > **Sessions**.
1. On the **Details** tab, scroll to the bottom.
1. Select **Cancel session**.
1. In the confirmation dialog, select **Cancel session** to confirm.

After cancellation:

- The session status changes to **Stopped**.
- The session cannot be resumed or restarted.

## Review and control agent actions

{{< details >}}

- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Prerequisites:

- Your custom flow must include a [`HumanInputComponent`](https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/-/blob/main/docs/flow_registry/v1.md#humaninputcomponent) in its flow definition YAML.

When a flow reaches a human interaction checkpoint, execution pauses and the session waits for your input.

### Approval notifications

When a flow pauses at a checkpoint, GitLab notifies you in two ways:

- **To-Do item**: A to-do item labeled **Duo Workflow approval required** is added to
  **Your work** > **To-Do List**. The item links directly to the session where you can take action.
  GitLab marks the to-do item as done automatically when you approve, reject, or modify the
  request, or when the workflow is canceled or stopped.
- **Email**: An email notification is sent with the workflow name, the project it belongs to,
  a summary of completed actions and the pending request, and a direct link to the approval UI.

### Respond to an agent checkpoint

To review and respond to an agent checkpoint:

1. On the GitLab Duo sidebar, select **Sessions**.
1. Select the session that is waiting for your review.
1. Review the agent's completed actions and its proposed next steps.
1. Select one of the following:
   - **Approve**: Allow the agent to continue with its planned actions.
   - **Reject**: Stop the flow execution immediately.
   - **Modify**: Send feedback or a suggestion to the agent. The agent returns to the checkpoint for another review.

## Session retention

Sessions are automatically deleted 30 days after the last activity.
The retention period resets each time you interact with the session.
For example, if you interact with a session every 20 days, it will never be automatically deleted.

In the IDE, you can also manually delete sessions before the 30-day retention period expires.

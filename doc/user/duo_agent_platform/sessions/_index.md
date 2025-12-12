---
stage: AI-powered
group: Agent Foundations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Sessions
---

{{< details >}}

- Tier: Premium, Ultimate
- Add-on: GitLab Duo Core, Pro, or Enterprise
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Status: Beta

{{< /details >}}

Sessions show the status and execution data for the agents and flows you've run.

Sessions are created by GitLab Duo Chat (Agentic) and foundational flows in the IDE or UI. Examples include:

- Flows that are executed on a runner, like the [Fix your CI/CD Pipeline Flow](../flows/fix_pipeline.md).
  These sessions are visible in the UI under **Automate** > **Sessions**.
- Flows that run in the IDE, like the [Software development Flow](../flows/software_development.md).
  These sessions are visible in the IDE, on the **Flows** tab, under **Sessions**.
- Sessions created by GitLab Duo Chat. These sessions are visible on the right sidebar
  by selecting **GitLab Duo Chat history**.
- Flows that are invoked by triggers. These sessions are visible in the UI under **Automate** > **Sessions**.

GitLab Duo Chat (Classic) does not create sessions, because it's not agentic.

## View sessions for your project

Prerequisites:

- You must have the Developer, Maintainer, or Owner role for the project.

To view sessions for your project:

1. On the top bar, select **Search or go to** and find your project.
1. Select **Automate** > **Sessions**.
1. Select any session to view more details.

## View sessions you've triggered

To view sessions you've triggered:

1. On the right sidebar, select **GitLab Duo sessions**.
1. Select any session to view more details.
1. Optional. Filter the details to show all logs or a concise subset only.

## GitLab Duo Chat (Agentic) sessions

Because chats are interactive, they require a clearer separation in the UI.
You can think of the Chat history as a filtered view of sessions that exists
exclusively for Chats.

## Cancel a running session

You can cancel a session that is running or waiting for input. To cancel a session:

1. On the top bar, select **Search or go to** and find your project.
1. Select **Automate** > **Sessions**.
1. On the **Details** tab, scroll to the bottom.
1. Select **Cancel session**.
1. In the confirmation dialog, select **Cancel session** to confirm.

After cancellation:

- The session status changes to **Stopped**.
- The session cannot be resumed or restarted.

## Session retention

Sessions are automatically deleted 30 days after the last activity.
The retention period resets each time you interact with the session.
For example, if you interact with a session every 20 days, it will never be automatically deleted.

In the IDE, you can also manually delete sessions before the 30-day retention period expires.

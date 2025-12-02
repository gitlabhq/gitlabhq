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

Sessions show the status of the agents and flows you've run in GitLab.

## Which actions create sessions

In the Agent Platform, sessions are created when you:

- Run an agent or flow in the GitLab UI. This includes:
  - Flows like the [Fix your CI/CD Pipeline Flow](../flows/fix_pipeline.md).
  - Any flow invoked with a trigger.

Sessions are not created when:

- You use GitLab Duo Chat (Agentic) in VS Code or the GitLab UI.
- You invoke a custom flow from the GitLab Duo Chat UI.

## View the sessions for your project

Prerequisites:

- You must have the Developer, Maintainer, or Owner role for the project.

To view the sessions for your project:

1. On the left sidebar, select **Search or go to** and find your project. If you've [turned on the new navigation](../../interface_redesign.md#turn-new-navigation-on-or-off), this field is on the top bar.
1. Select **Automate** > **Sessions**.
1. Select any session to view more details.

## View sessions you've triggered

To view a list of sessions you've triggered:

1. On the right sidebar, select **GitLab Duo sessions**.
1. Select any session to view more details.
1. Optional. Filter the details to show all logs or a concise subset only.

## Session retention

Sessions are automatically deleted 30 days after the last activity.
The retention period resets each time you interact with the session.
For example, if you interact with a session every 20 days, it will never be automatically deleted.

In the IDE, you can also manually delete sessions before the 30-day retention period expires.

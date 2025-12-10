---
stage: AI-powered
group: Workflow Catalog
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Foundational agents
---

{{< details >}}

- Tier: Premium, Ultimate
- Add-on: GitLab Duo Core, Pro, or Enterprise
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/576618) in GitLab 18.6.
- Generally available in GitLab 18.7.

{{< /history >}}

Foundational agents are specialized AI assistants that extend the capabilities of GitLab Duo Chat
with domain-specific expertise and context awareness.

Unlike the general-purpose GitLab Duo agent, foundational agents understand the unique workflows,
frameworks, and best practices of their specialized domains. Each agent combines deep knowledge of
GitLab features with role-specific reasoning to provide targeted help that aligns with how
practitioners actually work.

Foundational agents are built and maintained by GitLab and display a GitLab-maintained badge ({{< icon name="tanuki-verified" >}}).

## Available foundational agents

The following foundational agents are available:

- [Planner](planner.md), for product management and
  planning workflows.
- [Security Analyst](security_analyst_agent.md), for
  security analysis and vulnerability management.
- [Data Analyst](data_analyst.md), for analysis
  and visualization of platform data.

## Duplicate an agent

To make changes to a foundational agent, create a copy of it.

Prerequisites:

- You must have at least the Maintainer role for the project.

To duplicate an agent:

1. On the top bar, select **Search or go to** > **Explore**.
1. Select **AI Catalog**, then select the **Agents** tab.
1. Select the agent you want to duplicate.
1. In the upper-right corner, select **Actions** ({{< icon name="ellipsis_v" >}}) > **Duplicate**.
1. Under **Visibility & access**:
   1. From the **Managed by** dropdown list, select a project for the agent.
   1. For **Visibility**, select **Private** or **Public**.
1. Optional. Edit any fields you want to change.
1. Select **Create agent**.

A custom agent is created. To use it, you must [enable it](../custom.md#enable-an-agent).

## Turn foundational agents on or off

By default, foundational agents are turned on.
You can turn them on or off for a top-level group (namespace) or for an instance.

If you turn foundational agents off, you can still use the default GitLab Duo agent.

{{< tabs >}}

{{< tab title="For GitLab.com" >}}

Prerequisites:

- You must have the Owner role for the group.

1. On the top bar, select **Search or go to** and find your group.
1. Select **Settings** > **GitLab Duo**.
1. Select **Change configuration**.
1. Under **Foundational agents**, select either:
   - **On by default**
   - **Off by default**
1. Select **Save changes**.

These settings apply to:

- Users who have the top-level group as the [default GitLab Duo namespace](../../../gitlab_duo/model_selection.md#assign-a-default-gitlab-duo-namespace).
- Users without a default namespace, and who visit a namespace that belongs to the top-level group.

If you turn off foundational agents for a top-level group, users with that group as their default GitLab Duo namespace can't access foundational agents in any namespace.

{{< /tab >}}

{{< tab title="For an instance" >}}

Prerequisites:

- You must be an administrator.

1. In the upper-right corner, select **Admin**.
1. Select **GitLab Duo**.
1. Select **Change configuration**.
1. Under **Foundational agents**, select either:
   - **On by default**
   - **Off by default**
1. Select **Save changes**.

{{< /tab >}}

{{< /tabs >}}

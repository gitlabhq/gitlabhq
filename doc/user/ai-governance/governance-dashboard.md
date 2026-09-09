---
stage: Software Supply Chain Security
group: AI Governance
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: Monitor AI agent sessions, audit logs, and developer exposure across your organization from a central dashboard.
title: AI Governance Dashboard
---

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com
- Status: Limited availability

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/work_items/603776) in GitLab 19.4 in [beta](../../policy/development_stages_support.md) with a [feature flag](../../administration/feature_flags/_index.md) named `ai_governance_dashboard`. Disabled by default.

{{< /history >}}

> [!warning]
> This feature is in [beta](../../policy/development_stages_support.md).
> It is subject to change without notice.
> For more information, see [GitLab Testing Agreement](https://handbook.gitlab.com/handbook/legal/testing-agreement/).

Security and compliance teams can use AI Governance Dashboard to monitor AI agent activity across a
group. AI Governance Dashboard surfaces key performance indicators and data cards that give you
visibility on:

- How AI agents are being used.
- Which developers are most active.
- Which projects have the most exposure.

The dashboard shows data for GitLab Duo Agent Platform (DAP) agents only, scoped to the last 7 days.

## Prerequisites

- You have the Owner role for the top-level group, or a custom role with the
  `read_agent_artifacts` ability.
- The `ai_governance_dashboard` feature flag is enabled for your group.

## View the dashboard

1. In the top bar, select **Search or go to** and find your top-level group.
1. Select **Settings** > **GitLab Duo**.
1. Select **Change governance**.
1. Select the **Dashboard** tab.

## Key performance indicator (KPI) tiles

The dashboard header shows two KPI tiles. Each tile displays a count for the
last 7 days and a sparkline showing the daily trend over that period.

### AI agents

The **AI agents** tile shows the number of distinct active agent instances in
the last 7 days. An agent instance is unique per user, project, namespace, agent
type, and environment. Duo Chat conversations are excluded from this count.

### AI sessions

The **AI sessions** tile shows the total number of agent workflow sessions in
the last 7 days. This includes all DAP workflow types: IDE, web, chat, and
ambient sessions. Duo Chat is included.

## Data cards

Below the KPI tiles, four data cards provide breakdowns of agent activity.

### Audit logs

The **Audit logs** card links to the [AI audit event report](ai-audit-events.md),
where you can browse, filter, and download a full record of agent session events.
Filters applied on the dashboard are passed through to the audit events tab.

### AI agent inventory

The **AI agent inventory** card lists the DAP agents active in your group,
broken down by project. You can sort agents by usage to identify the most
frequently invoked agents.

### Developer activity

The **Developer activity** card shows the top users by agent session count
over the last 7 days. Use this to understand which developers are most actively
using AI agents.

### Project exposure

The **Project exposure** card shows the top projects by agent session count
over the last 7 days. Use this to identify which projects have the highest
volume of AI agent activity.

## Related topics

- [AI Governance](_index.md)
- [Tool governance](tool-governance.md)
- [GitLab Duo Agent Platform](../duo_agent_platform/_index.md)
